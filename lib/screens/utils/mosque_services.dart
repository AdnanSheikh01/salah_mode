import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'mosque_model.dart';

class MosqueService {
  // ── Overpass API endpoint ──────────────────────────────────────
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const _radiusMeters = 3000; // 3 km

  // ─────────────────────────────────────────────────────────────
  //  LOCATION HELPER
  // ─────────────────────────────────────────────────────────────

  /// Requests permission if needed and returns the device position.
  /// Throws a descriptive [Exception] for every failure case so the
  /// caller can show a meaningful message.
  Future<Position> getUserLocation() async {
    // 1. Check if location service is on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. '
        'Please enable GPS in your device settings.',
      );
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. '
          'Please grant location access to find nearby mosques.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. '
        'Enable it in your device Settings.',
      );
    }

    // 3. Get position
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
        'Location request timed out. '
        'Make sure GPS is enabled and try again.',
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  FETCH USING DEVICE GPS  (no parameters — uses Geolocator)
  // ─────────────────────────────────────────────────────────────

  Future<List<Mosque>> fetchNearbyMosques() async {
    final pos = await getUserLocation();
    return _fetchMosquesAt(lat: pos.latitude, lon: pos.longitude);
  }

  // ─────────────────────────────────────────────────────────────
  //  FETCH AT SPECIFIC COORDINATES  (city search / map tap)
  // ─────────────────────────────────────────────────────────────

  Future<List<Mosque>> fetchNearbyMosquesAt({
    required double lat,
    required double lon,
  }) async {
    return _fetchMosquesAt(lat: lat, lon: lon);
  }

  // ─────────────────────────────────────────────────────────────
  //  SHARED FETCH LOGIC
  // ─────────────────────────────────────────────────────────────

  Future<List<Mosque>> _fetchMosquesAt({
    required double lat,
    required double lon,
  }) async {
    // Build Overpass QL query
    final query =
        '[out:json];'
        'node(around:$_radiusMeters,$lat,$lon)'
        '[amenity=place_of_worship][religion=muslim];'
        'out;';

    final uri = Uri.parse(_overpassUrl);

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 20));
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Overpass API returned status ${response.statusCode}. '
        'Please try again later.',
      );
    }

    // Parse response
    Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Unexpected response format from mosque API.');
    }

    final elements = data['elements'];
    if (elements == null || elements is! List) return [];

    final mosques = <Mosque>[];

    for (final el in elements) {
      try {
        final mLat = (el['lat'] as num?)?.toDouble();
        final mLon = (el['lon'] as num?)?.toDouble();
        if (mLat == null || mLon == null) continue;

        final distance =
            Geolocator.distanceBetween(lat, lon, mLat, mLon) / 1000;

        // Prefer English name, fallback to any "name:*", then default
        final tags = el['tags'] as Map<String, dynamic>? ?? {};
        final name =
            (tags['name:en'] as String?)?.trim() ??
            (tags['name'] as String?)?.trim() ??
            'Nearby Mosque';

        mosques.add(
          Mosque(name: name, lat: mLat, lon: mLon, distance: distance),
        );
      } catch (_) {
        // Skip malformed element — never crash the whole list
        continue;
      }
    }

    mosques.sort((a, b) => a.distance.compareTo(b.distance));
    return mosques;
  }
}
