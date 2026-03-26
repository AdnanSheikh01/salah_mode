import 'dart:async';
import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:salah_mode/screens/home_bottom_navbar/tools/nearby_mosque/detailed_nearby_mosque.dart';
import 'package:salah_mode/screens/utils/mosque_model.dart';
import 'package:salah_mode/screens/utils/mosque_services.dart';
import 'package:salah_mode/screens/utils/point_service.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
// SORT OPTIONS
// ─────────────────────────────────────────────────────────────────
enum _SortMode { nearest, verified, alphabetical }

class NearbyMosqueScreen extends StatefulWidget {
  const NearbyMosqueScreen({super.key});
  @override
  State<NearbyMosqueScreen> createState() => _NearbyMosqueScreenState();
}

class _NearbyMosqueScreenState extends State<NearbyMosqueScreen> {
  final MosqueService _service = MosqueService();

  List<Mosque> _mosques = [];
  List<Mosque> _userMosques = [];
  Map<String, int> _votes = {}; // verify votes count per mosque
  Map<String, int> _deleteVotes = {}; // delete votes count per mosque
  Set<String> _myVotedIds = {}; // mosques THIS device already verified
  Set<String> _myDeletedIds = {}; // mosques THIS device already voted to delete
  bool _loading = true;
  bool _mapExpanded = false;
  bool _locSearching = false;
  String _errorMsg = '';
  int? _selectedIdx;
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.nearest;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _citySearchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // ── Stable ID ─────────────────────────────────────────────────
  static String _id(Mosque m) =>
      "${m.name}_${m.lat.toStringAsFixed(5)}_${m.lon.toStringAsFixed(5)}";

  static String _walkTime(double km) {
    if (km <= 0) return '';
    final mins = (km / 5.0 * 60).round();
    return mins < 60
        ? "$mins min walk"
        : "${(mins / 60).toStringAsFixed(1)} hr walk";
  }

  // ── Filtered + sorted ─────────────────────────────────────────
  List<Mosque> get _displayed {
    var list = _mosques.where((m) {
      if (_searchQuery.trim().isEmpty) return true;
      return m.name.toLowerCase().contains(_searchQuery.toLowerCase().trim());
    }).toList();
    switch (_sortMode) {
      case _SortMode.nearest:
        list.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case _SortMode.verified:
        list.sort(
          (a, b) => (_isVerified(a) ? 0 : 1).compareTo(_isVerified(b) ? 0 : 1),
        );
        break;
      case _SortMode.alphabetical:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _citySearchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMsg = '';
    });
    try {
      await _loadUserMosques();
      final api = await _service.fetchNearbyMosques().timeout(
        const Duration(seconds: 15),
      );
      _mosques = [...api, ..._userMosques];
      if (_mosques.isNotEmpty) await _loadVotes();
    } catch (e) {
      log("Mosque load error: $e");
      _mosques = [..._userMosques];
      if (_mosques.isEmpty) {
        _errorMsg =
            "Unable to find mosques nearby.\n"
            "Check your location permissions and internet.";
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Votes: verify + delete + "my votes" ──────────────────────
  Future<void> _loadVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final m in _mosques) {
        final id = _id(m);
        _votes[id] = prefs.getInt('verify_$id') ?? 0;
        _deleteVotes[id] = prefs.getInt('delete_vote_$id') ?? 0;
      }
      // Load this device's already-cast votes
      _myVotedIds = (prefs.getStringList('my_verify_votes') ?? []).toSet();
      _myDeletedIds = (prefs.getStringList('my_delete_votes') ?? []).toSet();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Vote load error: $e");
    }
  }

  // ── Verify (once per device) ──────────────────────────────────
  Future<void> _verifyMosque(Mosque m) async {
    final id = _id(m);

    // Already voted → show snack and return
    if (_myVotedIds.contains(id)) {
      Get.snackbar(
        "Already Confirmed",
        "You have already confirmed this mosque.",
        backgroundColor: AppTheme.colorWarning,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final next = (_votes[id] ?? 0) + 1;
      _votes[id] = next;
      _myVotedIds.add(id);
      await prefs.setInt('verify_$id', next);
      await prefs.setStringList('my_verify_votes', _myVotedIds.toList());
      // Award 15 points for each mosque verification (syncs to Firestore bg)
      await PointsService.instance.award(PointEvent.mosqueVerification);
      if (mounted) setState(() {});

      // Celebrate when newly verified
      if (next >= 3) {
        Get.snackbar(
          "Mosque Verified ✦",
          "This mosque now has enough confirmations!",
          backgroundColor: AppTheme.colorSuccess,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final remaining = 3 - next;
        Get.snackbar(
          "Confirmation Recorded",
          "$remaining more confirmation${remaining == 1 ? '' : 's'} needed.",
          backgroundColor: AppTheme.colorInfo,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint("Verify error: $e");
    }
  }

  bool _isVerified(Mosque m) => (_votes[_id(m)] ?? 0) >= 3;
  bool _hasMyVote(Mosque m) => _myVotedIds.contains(_id(m));

  // ── Delete vote (3 needed, once per device) ───────────────────
  Future<void> _voteToDelete(Mosque m) async {
    final id = _id(m);

    if (_myDeletedIds.contains(id)) {
      Get.snackbar(
        "Already Voted",
        "You have already voted to remove this mosque.",
        backgroundColor: AppTheme.colorWarning,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final next = (_deleteVotes[id] ?? 0) + 1;
      _deleteVotes[id] = next;
      _myDeletedIds.add(id);
      await prefs.setInt('delete_vote_$id', next);
      await prefs.setStringList('my_delete_votes', _myDeletedIds.toList());

      if (next >= 3) {
        // Threshold reached — actually remove
        await _hardDeleteMosque(m);
        Get.snackbar(
          "Mosque Removed",
          "Enough reports received. The mosque has been removed.",
          backgroundColor: AppTheme.colorError,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final remaining = 3 - next;
        if (mounted) setState(() {});
        Get.snackbar(
          "Report Recorded",
          "$remaining more report${remaining == 1 ? '' : 's'} needed to remove.",
          backgroundColor: AppTheme.colorWarning,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint("Delete vote error: $e");
    }
  }

  Future<void> _hardDeleteMosque(Mosque m) async {
    final id = _id(m);
    _mosques.removeWhere((x) => _id(x) == id);
    _userMosques.removeWhere((x) => _id(x) == id);
    _votes.remove(id);
    _deleteVotes.remove(id);
    await _saveUserMosques();
    // Clean up prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('verify_$id');
    await prefs.remove('delete_vote_$id');
    if (mounted) setState(() {});
  }

  // User-added mosque: owner can directly delete from swipe
  Future<void> _ownerDelete(Mosque m) async {
    _userMosques.removeWhere((u) => _id(u) == _id(m));
    _mosques.removeWhere((x) => _id(x) == _id(m));
    await _saveUserMosques();
    if (mounted) setState(() {});
  }

  Future<void> _loadUserMosques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_mosques');
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _userMosques = list
          .map(
            (e) => Mosque(
              name: (e['name'] ?? 'Unknown').toString(),
              lat: (e['lat'] as num).toDouble(),
              lon: (e['lon'] as num).toDouble(),
              distance: (e['distance'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("User mosque load error: $e");
    }
  }

  Future<void> _saveUserMosques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_mosques',
        jsonEncode(
          _userMosques
              .map(
                (m) => {
                  'name': m.name,
                  'lat': m.lat,
                  'lon': m.lon,
                  'distance': m.distance,
                },
              )
              .toList(),
        ),
      );
    } catch (e) {
      debugPrint("User mosque save error: $e");
    }
  }

  Future<void> _openDirections(Mosque m) async {
    try {
      final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1"
        "&destination=${m.lat},${m.lon}&travelmode=walking",
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Direction launch error: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  CITY SEARCH (for both recovery view & add dialog)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _searchByCity(String cityName) async {
    final query = cityName.trim();
    if (query.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _locSearching = true;
      _errorMsg = '';
    });
    try {
      final geoUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final geoResp = await http
          .get(
            geoUrl,
            headers: {
              'User-Agent': 'salah_mode_app/1.0',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (geoResp.statusCode != 200) {
        _setSearchError(
          'Geocoding failed (${geoResp.statusCode}). Try a different name.',
        );
        return;
      }
      List<dynamic> geoData;
      try {
        geoData = jsonDecode(geoResp.body) as List<dynamic>;
      } catch (_) {
        _setSearchError('Unexpected response from geocoding service.');
        return;
      }
      if (geoData.isEmpty) {
        _setSearchError(
          'No location found for "$query". Try e.g. "Karachi, Pakistan".',
        );
        return;
      }
      final lat = double.tryParse(geoData[0]['lat']?.toString() ?? '');
      final lon = double.tryParse(geoData[0]['lon']?.toString() ?? '');
      if (lat == null || lon == null) {
        _setSearchError('Could not read coordinates for "$query".');
        return;
      }
      List<Mosque> result;
      try {
        result = await _service
            .fetchNearbyMosquesAt(lat: lat, lon: lon)
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        result = await _service.fetchNearbyMosques().timeout(
          const Duration(seconds: 15),
        );
      }
      _mosques = [...result, ..._userMosques];
      if (_mosques.isNotEmpty) await _loadVotes();
      _errorMsg = _mosques.isEmpty ? 'No mosques found near "$query".' : '';
      if (mounted) setState(() => _locSearching = false);
    } on http.ClientException catch (e) {
      debugPrint('City search network error: $e');
      _setSearchError('Network error. Check your internet connection.');
    } catch (e) {
      debugPrint('City search error: $e');
      _setSearchError('Something went wrong. Please try again.');
    }
  }

  void _setSearchError(String msg) {
    if (!mounted) return;
    setState(() {
      _locSearching = false;
      _errorMsg = msg;
    });
  }

  Future<void> _showAddDialog(
    BuildContext ctx, {
    required Color accentColor,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color inputFill,
    required Color btnTextColor,
    required Color textTertiary,
    required Color cardAltColor,
  }) async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final mapCtrl = MapController();
    double pickedLat = _mosques.isNotEmpty ? _mosques.first.lat : 21.4225;
    double pickedLon = _mosques.isNotEmpty ? _mosques.first.lon : 39.8262;
    bool locPicked = false;
    bool geocoding = false;
    String? nameError;
    String? geoError;

    await showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, localSet) {
          // ── Geocode address → move pin ──────────────────────
          Future<void> resolveAddress() async {
            final addr = addressCtrl.text.trim();
            if (addr.isEmpty) return;
            localSet(() {
              geocoding = true;
              geoError = null;
            });
            try {
              final url = Uri.parse(
                'https://nominatim.openstreetmap.org/search'
                '?q=${Uri.encodeComponent(addr)}&format=json&limit=1',
              );
              final resp = await http
                  .get(
                    url,
                    headers: {
                      'User-Agent': 'salah_mode_app/1.0',
                      'Accept-Language': 'en',
                    },
                  )
                  .timeout(const Duration(seconds: 10));
              final data = jsonDecode(resp.body) as List<dynamic>;
              if (data.isEmpty) {
                localSet(() {
                  geocoding = false;
                  geoError = 'Address not found. Try a more specific name.';
                });
                return;
              }
              final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
              final lon = double.tryParse(data[0]['lon']?.toString() ?? '');
              if (lat == null || lon == null) {
                localSet(() {
                  geocoding = false;
                  geoError = 'Invalid coordinates.';
                });
                return;
              }
              localSet(() {
                pickedLat = lat;
                pickedLon = lon;
                locPicked = true;
                geocoding = false;
                geoError = null;
              });
              // Fly the map to the resolved location
              try {
                mapCtrl.move(LatLng(lat, lon), 16.0);
              } catch (_) {}
            } catch (e) {
              localSet(() {
                geocoding = false;
                geoError = 'Search failed. Check internet.';
              });
            }
          }

          return AnimatedPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 150),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: borderColor, width: 0.8)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      children: [
                        Icon(
                          Icons.mosque_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Add a Masjid",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Masjid Name ───────────────────────────────
                    _buildField(
                      controller: nameCtrl,
                      hint: "Masjid name...",
                      icon: Icons.edit_rounded,
                      errorText: nameError,
                      onChanged: (_) => localSet(() => nameError = null),
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      inputFill: inputFill,
                    ),
                    const SizedBox(height: 10),

                    // ── Address Search with live suggestions ─────
                    _AddressSuggestionField(
                      controller: addressCtrl,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      cardAltColor: cardAltColor,
                      borderColor: borderColor,
                      inputFill: inputFill,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textTertiary: textTertiary,
                      btnTextColor: btnTextColor,
                      geoError: geoError,
                      geocoding: geocoding,
                      onSearch: resolveAddress,
                      onErrorClear: () => localSet(() => geoError = null),
                      onSuggestionPicked: (lat, lon, displayName) {
                        localSet(() {
                          pickedLat = lat;
                          pickedLon = lon;
                          locPicked = true;
                          geocoding = false;
                          geoError = null;
                          addressCtrl.text = displayName;
                        });
                        // Fly to the selected suggestion
                        try {
                          mapCtrl.move(LatLng(lat, lon), 16.0);
                        } catch (_) {}
                      },
                    ),

                    const SizedBox(height: 12),

                    // ── Map pin picker ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 13,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "Or tap map to pin location",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        if (locPicked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.colorSuccess.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.colorSuccess.withOpacity(0.30),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 11,
                                  color: AppTheme.colorSuccess,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  "Location set",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.colorSuccess,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          mapController: mapCtrl,
                          options: MapOptions(
                            initialCenter: LatLng(pickedLat, pickedLon),
                            initialZoom: 15,
                            onTap: (_, latLng) {
                              localSet(() {
                                pickedLat = latLng.latitude;
                                pickedLon = latLng.longitude;
                                locPicked = true;
                              });
                              // No need to move — user already sees tap location
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              userAgentPackageName: "com.example.salah_mode",
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(pickedLat, pickedLon),
                                  width: 44,
                                  height: 44,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: locPicked
                                          ? AppTheme.colorSuccess
                                          : accentColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.mosque_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        "📍 ${pickedLat.toStringAsFixed(5)}, ${pickedLon.toStringAsFixed(5)}",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: textTertiary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Action buttons ────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(sheetCtx),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.22),
                                  width: 0.8,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                localSet(
                                  () => nameError = "Enter a masjid name",
                                );
                                return;
                              }
                              // Calculate distance using user's first mosque location
                              // as reference, or 0 if not available
                              double dist = 0;
                              if (_mosques.isNotEmpty) {
                                final refLat = _mosques.first.lat;
                                final refLon = _mosques.first.lon;
                                // Haversine approximation (km)
                                const r = 6371.0;
                                final dlat =
                                    (pickedLat - refLat) * 3.14159 / 180;
                                final dlon =
                                    (pickedLon - refLon) * 3.14159 / 180;
                                final a =
                                    (dlat / 2) * (dlat / 2) +
                                    (refLat * 3.14159 / 180).abs() *
                                        (pickedLat * 3.14159 / 180).abs() *
                                        (dlon / 2) *
                                        (dlon / 2);
                                dist = r * 2 * a; // rough approximation
                              }

                              final m = Mosque(
                                name: name,
                                lat: pickedLat,
                                lon: pickedLon,
                                distance: dist,
                              );
                              _userMosques.add(m);
                              _mosques.add(m);
                              _votes[_id(m)] = 0;
                              _deleteVotes[_id(m)] = 0;
                              await _saveUserMosques();
                              if (mounted) setState(() {});
                              Navigator.pop(sheetCtx);
                              if (mounted) {
                                final isDark =
                                    Theme.of(context).brightness ==
                                    Brightness.dark;
                                Get.snackbar(
                                  "Masjid Added ✦",
                                  "$name has been added to the map.",
                                  backgroundColor: accentColor,
                                  colorText: isDark
                                      ? AppTheme.darkTextOnAccent
                                      : AppTheme.lightTextOnAccent,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 12,
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 2),
                                );
                              }
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Add Masjid",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: btnTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Reusable text field builder ───────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color inputFill,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: textPrimary),
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: textSecondary,
        ),
        errorText: errorText,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon, size: 18, color: accentColor.withOpacity(0.70)),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.colorError, width: 1),
        ),
      ),
    );
  }

  // ── Delete confirmation (for user-own mosques via swipe) ──────
  Future<void> _confirmOwnerDelete(
    Mosque m, {
    required Color accentColor,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color btnTextColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.colorError.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.colorError.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.colorError,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Remove Your Masjid?",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Remove \"${m.name}\" from your list?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withOpacity(0.22),
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.colorError,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Remove",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) await _ownerDelete(m);
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final cardAltColor = isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final textTertiary = isDark
        ? AppTheme.darkTextTertiary
        : AppTheme.lightTextTertiary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final inputFill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    final displayed = _displayed;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "Nearby Mosques",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showAddDialog(
                context,
                accentColor: accentColor,
                cardColor: cardColor,
                cardAltColor: cardAltColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                inputFill: inputFill,
                btnTextColor: btnTextColor,
                textTertiary: textTertiary,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      "Add",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? _LoadingView(accentColor: accentColor, textSecondary: textSecondary)
          : _errorMsg.isNotEmpty && _mosques.isEmpty
          ? _LocationRecoveryView(
              message: _errorMsg,
              cityCtrl: _citySearchCtrl,
              locSearching: _locSearching,
              accentColor: accentColor,
              cardColor: cardColor,
              cardAltColor: cardAltColor,
              borderColor: borderColor,
              inputFill: inputFill,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textTertiary: textTertiary,
              btnTextColor: btnTextColor,
              onRetryLocation: _load,
              onSearchCity: _searchByCity,
            )
          : Column(
              children: [
                _MapSection(
                  mosques: _mosques,
                  selectedIndex: _selectedIdx,
                  expanded: _mapExpanded,
                  isVerified: _isVerified,
                  accentColor: accentColor,
                  borderColor: borderColor,
                  onToggleExpand: () =>
                      setState(() => _mapExpanded = !_mapExpanded),
                  onMarkerTap: (i) => setState(() => _selectedIdx = i),
                ),

                // ── Search + sort ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MosqueSearchBar(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          cardAltColor: cardAltColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textTertiary: textTertiary,
                          onChanged: (v) {
                            // Update query WITHOUT rebuilding search bar widget
                            if (_searchQuery != v) {
                              setState(() => _searchQuery = v);
                            }
                          },
                          onClear: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showSortSheet(
                          context,
                          accentColor: accentColor,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: cardAltColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          child: Icon(
                            Icons.sort_rounded,
                            size: 20,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Stats ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                  child: Row(
                    children: [
                      _StatPill(
                        icon: Icons.mosque_rounded,
                        label:
                            "${_mosques.length} mosque${_mosques.length == 1 ? '' : 's'}",
                        accentColor: accentColor,
                        cardAltColor: cardAltColor,
                        borderColor: borderColor,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: Icons.verified_rounded,
                        label: "${_mosques.where(_isVerified).length} verified",
                        accentColor: AppTheme.colorSuccess,
                        cardAltColor: cardAltColor,
                        borderColor: borderColor,
                        textSecondary: textSecondary,
                      ),
                      if (_userMosques.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _StatPill(
                          icon: Icons.person_pin_rounded,
                          label: "${_userMosques.length} by you",
                          accentColor: goldColor,
                          cardAltColor: cardAltColor,
                          borderColor: borderColor,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── List ──────────────────────────────────────
                Expanded(
                  child: displayed.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: textTertiary.withOpacity(0.40),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No mosques found",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                          itemCount: displayed.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            if (i >= displayed.length) {
                              return const SizedBox.shrink();
                            }
                            final m = displayed[i];
                            final verified = _isVerified(m);
                            final isNearest =
                                _sortMode == _SortMode.nearest && i == 0;
                            final isSelected =
                                _selectedIdx != null &&
                                _mosques.indexOf(m) == _selectedIdx;
                            final userAdded = _userMosques.any(
                              (u) => _id(u) == _id(m),
                            );
                            final walk = m.distance > 0
                                ? _walkTime(m.distance)
                                : '';
                            final votes = _votes[_id(m)] ?? 0;
                            final delVotes = _deleteVotes[_id(m)] ?? 0;
                            final myVoted = _hasMyVote(m);

                            return Dismissible(
                              key: ValueKey(_id(m)),
                              direction: userAdded
                                  ? DismissDirection.endToStart
                                  : DismissDirection.none,
                              confirmDismiss: userAdded
                                  ? (_) async {
                                      await _confirmOwnerDelete(
                                        m,
                                        accentColor: accentColor,
                                        cardColor: cardColor,
                                        borderColor: borderColor,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        btnTextColor: btnTextColor,
                                      );
                                      return false;
                                    }
                                  : null,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.colorError.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppTheme.colorError.withOpacity(
                                      0.30,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.colorError,
                                  size: 22,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _selectedIdx = _mosques.indexOf(m),
                                  );
                                  Get.to(
                                    () => MosqueDetailPage(
                                      mosqueName: m.name,
                                      mosqueId: _id(m),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    13,
                                    14,
                                    13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accentColor.withOpacity(0.08)
                                        : isNearest
                                        ? AppTheme.colorSuccess.withOpacity(
                                            0.07,
                                          )
                                        : cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? accentColor.withOpacity(0.40)
                                          : isNearest
                                          ? AppTheme.colorSuccess.withOpacity(
                                              0.30,
                                            )
                                          : borderColor,
                                      width: isSelected || isNearest
                                          ? 1.0
                                          : 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Icon circle
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: verified
                                              ? AppTheme.colorSuccess
                                                    .withOpacity(0.12)
                                              : accentColor.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: verified
                                                ? AppTheme.colorSuccess
                                                      .withOpacity(0.30)
                                                : accentColor.withOpacity(0.20),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.mosque_rounded,
                                          color: verified
                                              ? AppTheme.colorSuccess
                                              : accentColor,
                                          size: 22,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Name + info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    m.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (isNearest) ...[
                                                  const SizedBox(width: 6),
                                                  _Badge(
                                                    "Nearest",
                                                    AppTheme.colorSuccess,
                                                  ),
                                                ],
                                                if (userAdded) ...[
                                                  const SizedBox(width: 4),
                                                  _Badge("Added", goldColor),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (walk.isNotEmpty) ...[
                                                  Icon(
                                                    Icons
                                                        .directions_walk_rounded,
                                                    size: 12,
                                                    color: textTertiary,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    walk,
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 11,
                                                      color: textTertiary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                if (verified)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.verified_rounded,
                                                        size: 12,
                                                        color: AppTheme
                                                            .colorSuccess,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        "Verified",
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .colorSuccess,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Text(
                                                    "${(3 - votes).clamp(0, 3)} confirmations",
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 11,
                                                      color:
                                                          AppTheme.colorWarning,
                                                    ),
                                                  ),
                                                // Delete vote indicator
                                                if (delVotes > 0 &&
                                                    !userAdded) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.colorError
                                                          .withOpacity(0.10),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      border: Border.all(
                                                        color: AppTheme
                                                            .colorError
                                                            .withOpacity(0.25),
                                                        width: 0.6,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "$delVotes/3 reports",
                                                      style: const TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 9,
                                                        color:
                                                            AppTheme.colorError,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // Action buttons
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _IconBtn(
                                            icon: Icons.directions_rounded,
                                            color: accentColor,
                                            cardAltColor: cardAltColor,
                                            borderColor: borderColor,
                                            tooltip: "Get directions",
                                            onTap: () => _openDirections(m),
                                          ),
                                          const SizedBox(height: 6),
                                          // Verify OR report button
                                          verified
                                              ? _IconBtn(
                                                  icon: Icons.verified_rounded,
                                                  color: AppTheme.colorSuccess,
                                                  cardAltColor: cardAltColor,
                                                  borderColor: borderColor,
                                                  tooltip: "Verified",
                                                  onTap: null,
                                                )
                                              : myVoted
                                              ? _IconBtn(
                                                  icon: Icons.check_rounded,
                                                  color: AppTheme.colorInfo,
                                                  cardAltColor: cardAltColor,
                                                  borderColor: borderColor,
                                                  tooltip: "You confirmed this",
                                                  onTap: () => _verifyMosque(m),
                                                )
                                              : _IconBtn(
                                                  icon: Icons.verified_outlined,
                                                  color: textTertiary,
                                                  cardAltColor: cardAltColor,
                                                  borderColor: borderColor,
                                                  tooltip: "Confirm mosque",
                                                  onTap: () => _verifyMosque(m),
                                                ),
                                          const SizedBox(height: 6),
                                          // Report / delete vote (not for own mosques)
                                          if (!userAdded)
                                            _IconBtn(
                                              icon: Icons.flag_outlined,
                                              color: AppTheme.colorError,
                                              cardAltColor: cardAltColor,
                                              borderColor: borderColor,
                                              tooltip: "Report incorrect",
                                              onTap: () => _voteToDelete(m),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // ── Sort sheet ────────────────────────────────────────────────
  void _showSortSheet(
    BuildContext ctx, {
    required Color accentColor,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: borderColor, width: 0.8)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.sort_rounded, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Sort Mosques",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...[
              _SortMode.nearest,
              _SortMode.verified,
              _SortMode.alphabetical,
            ].map((mode) {
              final labels = {
                _SortMode.nearest: "Nearest First",
                _SortMode.verified: "Verified First",
                _SortMode.alphabetical: "Alphabetical",
              };
              final icons = {
                _SortMode.nearest: Icons.near_me_rounded,
                _SortMode.verified: Icons.verified_rounded,
                _SortMode.alphabetical: Icons.sort_by_alpha_rounded,
              };
              final active = _sortMode == mode;
              return GestureDetector(
                onTap: () {
                  setState(() => _sortMode = mode);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? accentColor.withOpacity(0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? accentColor.withOpacity(0.35)
                          : borderColor,
                      width: active ? 1.0 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icons[mode]!,
                        size: 18,
                        color: active ? accentColor : textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        labels[mode]!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active ? accentColor : textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (active)
                        Icon(Icons.check_rounded, size: 18, color: accentColor),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAP SECTION
// ═══════════════════════════════════════════════════════════════════

class _MapSection extends StatelessWidget {
  final List<Mosque> mosques;
  final int? selectedIndex;
  final bool expanded;
  final bool Function(Mosque) isVerified;
  final Color accentColor, borderColor;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onMarkerTap;

  const _MapSection({
    required this.mosques,
    required this.selectedIndex,
    required this.expanded,
    required this.isVerified,
    required this.accentColor,
    required this.borderColor,
    required this.onToggleExpand,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    final center = mosques.isNotEmpty
        ? LatLng(mosques.first.lat, mosques.first.lon)
        : const LatLng(21.4225, 39.8262);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: expanded ? 340 : 220,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.salah_mode",
              ),
              MarkerLayer(
                markers: List.generate(mosques.length, (i) {
                  final m = mosques[i];
                  final sel = selectedIndex == i;
                  final ver = isVerified(m);
                  return Marker(
                    point: LatLng(m.lat, m.lon),
                    width: sel ? 48 : 36,
                    height: sel ? 48 : 36,
                    child: GestureDetector(
                      onTap: () => onMarkerTap(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ver ? AppTheme.colorSuccess : accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.mosque_rounded,
                          color: Colors.white,
                          size: sel ? 24 : 18,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: onToggleExpand,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(0.30),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  expanded
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
            ),
          ),
          if (selectedIndex != null && selectedIndex! < mosques.length)
            Positioned(
              top: 10,
              left: 10,
              right: 54,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  mosques[selectedIndex!].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A3D2B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOCATION RECOVERY VIEW
// ═══════════════════════════════════════════════════════════════════

class _LocationRecoveryView extends StatefulWidget {
  final String message;
  final TextEditingController cityCtrl;
  final bool locSearching;
  final Color accentColor, cardColor, cardAltColor, borderColor, inputFill;
  final Color textPrimary, textSecondary, textTertiary, btnTextColor;
  final VoidCallback onRetryLocation;
  final ValueChanged<String> onSearchCity;

  const _LocationRecoveryView({
    required this.message,
    required this.cityCtrl,
    required this.locSearching,
    required this.accentColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.borderColor,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.btnTextColor,
    required this.onRetryLocation,
    required this.onSearchCity,
  });

  @override
  State<_LocationRecoveryView> createState() => _LocationRecoveryViewState();
}

class _LocationRecoveryViewState extends State<_LocationRecoveryView> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.colorError.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.colorError.withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: AppTheme.colorError,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Location Not Found",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: widget.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Option 1
          _OptionCard(
            label: "Option 1 — Use My Location",
            desc: "Grant location permission or enable GPS, then tap below.",
            accentColor: widget.accentColor,
            cardColor: widget.cardColor,
            borderColor: widget.borderColor,
            textSecondary: widget.textSecondary,
            child: GestureDetector(
              onTap: _retrying
                  ? null
                  : () async {
                      setState(() => _retrying = true);
                      widget.onRetryLocation();
                      if (mounted) setState(() => _retrying = false);
                    },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _retrying
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: widget.btnTextColor,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            size: 17,
                            color: widget.btnTextColor,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            "Fetch Current Location",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.btnTextColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: widget.borderColor, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  "OR",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.textTertiary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(child: Divider(color: widget.borderColor, height: 1)),
            ],
          ),
          const SizedBox(height: 16),

          // Option 2
          _OptionCard(
            label: "Option 2 — Search by City or Area",
            desc: "Type your city, neighbourhood or area name.",
            accentColor: widget.accentColor,
            cardColor: widget.cardColor,
            borderColor: widget.borderColor,
            textSecondary: widget.textSecondary,
            child: Column(
              children: [
                TextField(
                  controller: widget.cityCtrl,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: widget.textPrimary,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSearchCity,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "e.g. Karachi, Madinah, London...",
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: widget.textSecondary,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: widget.accentColor.withOpacity(0.70),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    suffixIcon: widget.cityCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              widget.cityCtrl.clear();
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: widget.textTertiary,
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: widget.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: widget.accentColor,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: widget.locSearching
                      ? null
                      : () => widget.onSearchCity(widget.cityCtrl.text),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.locSearching
                          ? widget.accentColor.withOpacity(0.50)
                          : widget.accentColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: widget.locSearching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: widget.btnTextColor,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.travel_explore_rounded,
                                size: 17,
                                color: widget.btnTextColor,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                "Search Mosques Here",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: widget.btnTextColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            "Makkah",
                            "Madinah",
                            "Karachi",
                            "Lahore",
                            "Cairo",
                            "Istanbul",
                            "London",
                            "Dubai",
                          ]
                          .map(
                            (city) => GestureDetector(
                              onTap: () {
                                widget.cityCtrl.text = city;
                                setState(() {});
                                widget.onSearchCity(city);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.cardAltColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.borderColor,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  city,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: widget.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.accentColor.withOpacity(0.18),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: widget.accentColor.withOpacity(0.70),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Make sure Location Services are enabled in your device settings. "
                    "The app needs location access to find mosques near you.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: widget.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label, desc;
  final Color accentColor, cardColor, borderColor, textSecondary;
  final Widget child;
  const _OptionCard({
    required this.label,
    required this.desc,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textSecondary,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  SMALL HELPERS
// ═══════════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  final Color accentColor, textSecondary;
  const _LoadingView({required this.accentColor, required this.textSecondary});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          strokeWidth: 2.5,
          color: accentColor,
          backgroundColor: accentColor.withOpacity(0.15),
        ),
        const SizedBox(height: 16),
        Text(
          "Finding mosques near you...",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor, cardAltColor, borderColor, textSecondary;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.cardAltColor,
    required this.borderColor,
    required this.textSecondary,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: cardAltColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: accentColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, cardAltColor, borderColor;
  final VoidCallback? onTap;
  final String tooltip;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.cardAltColor,
    required this.borderColor,
    required this.onTap,
    this.tooltip = '',
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cardAltColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? color.withOpacity(0.35) : color,
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  MOSQUE SEARCH BAR  (StatefulWidget — preserves focus on rebuild)
// ═══════════════════════════════════════════════════════════════════

class _MosqueSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color cardAltColor, borderColor, textPrimary, textTertiary;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _MosqueSearchBar({
    required this.controller,
    required this.focusNode,
    required this.cardAltColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textTertiary,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_MosqueSearchBar> createState() => _MosqueSearchBarState();
}

class _MosqueSearchBarState extends State<_MosqueSearchBar> {
  // Track locally so suffix icon rebuilds without losing focus
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: widget.cardAltColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderColor, width: 0.8),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: widget.textPrimary,
        ),
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: "Search mosques...",
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: widget.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 16,
            color: widget.textTertiary,
          ),
          suffixIcon: _hasText
              ? GestureDetector(
                  onTap: widget.onClear,
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: widget.textTertiary,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ADDRESS SUGGESTION FIELD  (debounced Nominatim typeahead)
// ═══════════════════════════════════════════════════════════════════

class _AddressSuggestionField extends StatefulWidget {
  final TextEditingController controller;
  final Color accentColor, cardColor, cardAltColor, borderColor, inputFill;
  final Color textPrimary, textSecondary, textTertiary, btnTextColor;
  final String? geoError;
  final bool geocoding;
  final VoidCallback onSearch;
  final VoidCallback onErrorClear;
  final void Function(double lat, double lon, String displayName)
  onSuggestionPicked;

  const _AddressSuggestionField({
    required this.controller,
    required this.accentColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.borderColor,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.btnTextColor,
    required this.geoError,
    required this.geocoding,
    required this.onSearch,
    required this.onErrorClear,
    required this.onSuggestionPicked,
  });

  @override
  State<_AddressSuggestionField> createState() =>
      _AddressSuggestionFieldState();
}

class _AddressSuggestionFieldState extends State<_AddressSuggestionField> {
  // ── Debounce ──────────────────────────────────────────────────
  Timer? _debounce;
  static const _debounceMs = 500;

  // ── Suggestion state ──────────────────────────────────────────
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = false;
  bool _showSuggestions = false;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        // Small delay so tap on suggestion registers before hiding
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    super.dispose();
  }

  // ── Fetch suggestions from Nominatim ─────────────────────────
  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 3) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loadingSuggestions = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query.trim())}'
        '&format=json&limit=5&addressdetails=1',
      );
      final resp = await http
          .get(
            url,
            headers: {
              'User-Agent': 'salah_mode_app/1.0',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        _suggestions = data
            .map(
              (e) => {
                'display_name': e['display_name'] ?? '',
                'lat': double.tryParse(e['lat']?.toString() ?? '') ?? 0.0,
                'lon': double.tryParse(e['lon']?.toString() ?? '') ?? 0.0,
                // Short label: city/town/village or first part of display_name
                'short': _shortName(e),
              },
            )
            .where((e) => (e['lat'] as double) != 0.0)
            .toList();

        setState(() {
          _loadingSuggestions = false;
          _showSuggestions = _suggestions.isNotEmpty && _focus.hasFocus;
        });
      } else {
        setState(() {
          _loadingSuggestions = false;
          _showSuggestions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingSuggestions = false;
          _showSuggestions = false;
        });
      }
    }
  }

  String _shortName(dynamic e) {
    try {
      final addr = e['address'] as Map<String, dynamic>?;
      if (addr != null) {
        final parts = <String>[];
        final primary =
            addr['mosque'] ??
            addr['place_of_worship'] ??
            addr['amenity'] ??
            addr['building'] ??
            addr['road'] ??
            addr['neighbourhood'] ??
            addr['suburb'] ??
            addr['city_district'];
        final city =
            addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'];
        final country = addr['country'];
        if (primary != null) parts.add(primary as String);
        if (city != null) parts.add(city as String);
        if (country != null) parts.add(country as String);
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {}
    // Fallback: first 60 chars of display_name
    final full = (e['display_name'] ?? '').toString();
    return full.length > 60 ? '${full.substring(0, 60)}…' : full;
  }

  void _onTextChanged(String value) {
    widget.onErrorClear();
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      _fetchSuggestions(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input row ─────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: widget.textPrimary,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onTextChanged,
                onSubmitted: (_) {
                  setState(() => _showSuggestions = false);
                  widget.onSearch();
                },
                decoration: InputDecoration(
                  hintText: "Search address or area...",
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: widget.textSecondary,
                  ),
                  errorText: widget.geoError,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: widget.accentColor.withOpacity(0.70),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: widget.controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            widget.controller.clear();
                            setState(() {
                              _suggestions = [];
                              _showSuggestions = false;
                            });
                            widget.onErrorClear();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: widget.textTertiary,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: widget.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: widget.accentColor,
                      width: 1.4,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.colorError,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Search button
            GestureDetector(
              onTap: widget.geocoding
                  ? null
                  : () {
                      setState(() => _showSuggestions = false);
                      widget.onSearch();
                    },
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: widget.geocoding
                      ? widget.accentColor.withOpacity(0.50)
                      : widget.accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: widget.geocoding
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: widget.btnTextColor,
                        ),
                      )
                    : Icon(
                        Icons.travel_explore_rounded,
                        color: widget.btnTextColor,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),

        // ── Suggestions dropdown ──────────────────────────────────
        if (_loadingSuggestions && !_showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Searching...",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: widget.textTertiary,
                  ),
                ),
              ],
            ),
          ),

        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.accentColor.withOpacity(0.25),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_suggestions.length, (i) {
                final s = _suggestions[i];
                final short = s['short'] as String;
                final full = s['display_name'] as String;
                final isLast = i == _suggestions.length - 1;

                return GestureDetector(
                  onTap: () {
                    widget.onSuggestionPicked(
                      s['lat'] as double,
                      s['lon'] as double,
                      short,
                    );
                    setState(() {
                      _showSuggestions = false;
                      _suggestions = [];
                    });
                    _focus.unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: widget.borderColor,
                                width: 0.6,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 15,
                          color: widget.accentColor.withOpacity(0.60),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                short,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.textPrimary,
                                ),
                              ),
                              if (full != short)
                                Text(
                                  full,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: widget.textTertiary,
                                    height: 1.4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
