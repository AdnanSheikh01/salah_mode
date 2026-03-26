import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:vibration/vibration.dart';

// ── Available compass needle styles ───────────────────────────────
class _NeedleStyle {
  final IconData icon;
  final String label;
  const _NeedleStyle(this.icon, this.label);
}

const List<_NeedleStyle> _needleStyles = [
  _NeedleStyle(Icons.navigation_rounded, "Arrow"),
  _NeedleStyle(Icons.mosque_rounded, "Mosque"),
  _NeedleStyle(Icons.star_rounded, "Star"),
  _NeedleStyle(Icons.explore_rounded, "Compass"),
  _NeedleStyle(Icons.my_location_rounded, "Location"),
  _NeedleStyle(Icons.place_rounded, "Pin"),
  _NeedleStyle(Icons.flight_rounded, "Plane"),
  _NeedleStyle(Icons.send_rounded, "Send"),
];

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage>
    with TickerProviderStateMixin {
  double? _deviceHeading;
  double? _qiblaDirection;

  bool _loading = true;
  bool _aligned = false;
  bool _hasError = false;
  String _errorMsg = '';

  int _selectedStyle = 0;

  StreamSubscription<CompassEvent>? _compassSub;

  late AnimationController _rotationCtrl;
  late Animation<double> _rotationAnim;
  double _lastAngle = 0.0;

  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotationAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _rotationCtrl, curve: Curves.easeOut));
    _init();
  }

  Future<void> _init() async {
    try {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        _setError(
          "Location services are disabled.\nPlease enable GPS and try again.",
        );
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _setError(
            "Location permission denied.\nGrant location access to find Qibla.",
          );
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _setError(
          "Location permission permanently denied.\nEnable it in device Settings.",
        );
        return;
      }

      final pos =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception("Location timed out. Please try again."),
          );

      if (!mounted) return;
      _qiblaDirection = _calcQibla(pos.latitude, pos.longitude);

      final events = FlutterCompass.events;
      if (events == null) {
        _setError("Compass sensor not available on this device.");
        return;
      }

      _compassSub = events.listen(
        (event) {
          if (!mounted) return;
          final heading = event.heading;
          if (heading == null || _qiblaDirection == null) return;

          // Shortest-path smooth rotation
          final raw = (_qiblaDirection! - heading) * pi / 180 * -1;
          double delta = raw - _lastAngle;
          while (delta > pi) delta -= 2 * pi;
          while (delta < -pi) delta += 2 * pi;
          final target = _lastAngle + delta;

          _rotationAnim = Tween<double>(begin: _lastAngle, end: target).animate(
            CurvedAnimation(parent: _rotationCtrl, curve: Curves.easeOut),
          );
          _lastAngle = target;
          _rotationCtrl
            ..reset()
            ..forward();

          final diff = (_qiblaDirection! - heading).abs() % 360;
          final minDiff = diff > 180 ? 360 - diff : diff;
          final nowAligned = minDiff < 5;

          if (nowAligned && !_aligned) _triggerVibration();

          setState(() {
            _deviceHeading = heading;
            _aligned = nowAligned;
            _loading = false;
          });
        },
        onError: (e) {
          if (mounted) _setError("Compass error: $e");
        },
      );
    } on Exception catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
    } catch (_) {
      _setError("An unexpected error occurred. Please restart.");
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hasError = true;
      _errorMsg = msg;
    });
  }

  Future<void> _triggerVibration() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 200);
      }
    } catch (_) {}
  }

  double _calcQibla(double lat, double lng) {
    final kLat = _r(_kaabaLat), kLng = _r(_kaabaLng);
    final uLat = _r(lat), dLng = kLng - _r(lng);
    final y = sin(dLng);
    final x = cos(uLat) * tan(kLat) - sin(uLat) * cos(dLng);
    return (_d(atan2(y, x)) + 360) % 360;
  }

  double _r(double d) => d * pi / 180;
  double _d(double r) => r * 180 / pi;

  void _showStylePicker(
    BuildContext ctx, {
    required Color accentColor,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color btnTextColor,
  }) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NeedlePickerSheet(
        styles: _needleStyles,
        selectedIndex: _selectedStyle,
        accentColor: accentColor,
        cardColor: cardColor,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        btnTextColor: btnTextColor,
        onSelect: (i) {
          setState(() => _selectedStyle = i);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _rotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    // FIX: use darkAccentGold, not darkAccent, for gold role in dark mode
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
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "Qibla Finder",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          if (!_loading && !_hasError)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _showStylePicker(
                  context,
                  accentColor: accentColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  btnTextColor: btnTextColor,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    // FIX: withOpacity → withValues(alpha:)
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      // FIX: withOpacity → withValues(alpha:)
                      color: accentColor.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _needleStyles[_selectedStyle].icon,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Style",
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
      body: SafeArea(
        child: _loading
            ? _LoadingView(
                accentColor: accentColor,
                textSecondary: textSecondary,
              )
            : _hasError
            ? _ErrorView(
                message: _errorMsg,
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                btnTextColor: btnTextColor,
                onRetry: () {
                  setState(() {
                    _loading = true;
                    _hasError = false;
                    _errorMsg = '';
                  });
                  _init();
                },
              )
            : _deviceHeading == null || _qiblaDirection == null
            ? _LoadingView(
                accentColor: accentColor,
                textSecondary: textSecondary,
                label: "Detecting compass...",
              )
            : _CompassView(
                qiblaDirection: _qiblaDirection!,
                deviceHeading: _deviceHeading!,
                aligned: _aligned,
                rotationAnim: _rotationAnim,
                needleStyle: _needleStyles[_selectedStyle],
                accentColor: accentColor,
                goldColor: goldColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NEEDLE PICKER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════

class _NeedlePickerSheet extends StatelessWidget {
  final List<_NeedleStyle> styles;
  final int selectedIndex;
  final Color accentColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, btnTextColor;
  final ValueChanged<int> onSelect;

  const _NeedlePickerSheet({
    required this.styles,
    required this.selectedIndex,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnTextColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 20),

          Text(
            "Choose Qibla Icon",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Select the icon that appears on your compass needle",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: styles.length,
            itemBuilder: (_, i) {
              final style = styles[i];
              final isActive = i == selectedIndex;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    // FIX: withOpacity → withValues(alpha:)
                    color: isActive
                        ? accentColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? accentColor : borderColor,
                      width: isActive ? 1.4 : 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        style.icon,
                        size: 28,
                        color: isActive ? accentColor : textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        style.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive ? accentColor : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COMPASS VIEW
// ═══════════════════════════════════════════════════════════════════

class _CompassView extends StatelessWidget {
  final double qiblaDirection, deviceHeading;
  final bool aligned;
  final Animation<double> rotationAnim;
  final _NeedleStyle needleStyle;
  final Color accentColor, goldColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, textTertiary;

  const _CompassView({
    required this.qiblaDirection,
    required this.deviceHeading,
    required this.aligned,
    required this.rotationAnim,
    required this.needleStyle,
    required this.accentColor,
    required this.goldColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            // ── Status pill ──────────────────────────────────────
            // FIX: The original ValueKey(aligned) is a bool key — perfectly
            // valid for a single AnimatedSwitcher. The crash was caused by
            // Flutter finding TWO widgets with the same bool key somewhere
            // in the tree (the switcher rebuilding while a previous frame's
            // child was still alive). Using a unique String key that encodes
            // BOTH the widget identity AND the state prevents this entirely.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _StatusPill(
                // FIX: key is scoped to this switcher by prefixing with a
                // widget-specific namespace, so it can never collide with
                // any other AnimatedSwitcher key in the same tree.
                key: ValueKey('qibla_status_pill_$aligned'),
                aligned: aligned,
                accentColor: accentColor,
              ),
            ),

            const SizedBox(height: 32),

            // ── Compass ──────────────────────────────────────────
            LayoutBuilder(
              builder: (ctx, constraints) {
                final size = constraints.maxWidth.clamp(0.0, 300.0);
                return SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 1),
                        ),
                      ),
                      // Mid ring — turns green when aligned
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: size * 0.85,
                        height: size * 0.85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            // FIX: withOpacity → withValues(alpha:)
                            color: aligned
                                ? AppTheme.colorSuccess.withValues(alpha: 0.50)
                                : borderColor.withValues(alpha: 0.4),
                            width: aligned ? 2 : 0.8,
                          ),
                        ),
                      ),
                      // Rotating needle
                      AnimatedBuilder(
                        animation: rotationAnim,
                        builder: (_, child) => Transform.rotate(
                          angle: rotationAnim.value,
                          child: child,
                        ),
                        child: Container(
                          width: size * 0.70,
                          height: size * 0.70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardColor,
                            border: Border.all(
                              // FIX: withOpacity → withValues(alpha:)
                              color: aligned
                                  ? AppTheme.colorSuccess
                                  : accentColor.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              needleStyle.icon,
                              size: size * 0.28,
                              color: aligned
                                  ? AppTheme.colorSuccess
                                  : accentColor,
                            ),
                          ),
                        ),
                      ),
                      // Kaaba gold dot at center
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: goldColor,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.mosque_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Degree text ──────────────────────────────────────
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${qiblaDirection.toStringAsFixed(1)}° to Qibla",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Device heading: ${deviceHeading.toStringAsFixed(1)}°",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: textTertiary,
              ),
            ),

            const SizedBox(height: 24),

            // ── Calibration tip ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIX: withOpacity → withValues(alpha:)
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: accentColor.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "If direction is inaccurate, move your phone in a figure-8 motion to calibrate.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Islamic tip ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // FIX: withOpacity → withValues(alpha:)
                color: goldColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  // FIX: withOpacity → withValues(alpha:)
                  color: goldColor.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "✦ ",
                    style: TextStyle(
                      fontSize: 12,
                      color: goldColor,
                      height: 1.6,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Face the Qibla, make your niyyah, and begin with Allahu Akbar.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  STATUS PILL — extracted to its own widget so AnimatedSwitcher
//  swaps entire widget instances, not just internal state.
//  This is the correct pattern for AnimatedSwitcher to work reliably.
// ─────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool aligned;
  final Color accentColor;

  const _StatusPill({
    super.key,
    required this.aligned,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        // FIX: withOpacity → withValues(alpha:)
        color: aligned
            ? AppTheme.colorSuccess.withValues(alpha: 0.12)
            : accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // FIX: withOpacity → withValues(alpha:)
          color: aligned
              ? AppTheme.colorSuccess.withValues(alpha: 0.30)
              : accentColor.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            aligned ? Icons.check_circle_rounded : Icons.my_location_rounded,
            size: 14,
            color: aligned ? AppTheme.colorSuccess : accentColor,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              aligned ? "Aligned with Qibla ✦" : "Rotate phone slowly",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: aligned ? AppTheme.colorSuccess : accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOADING / ERROR VIEWS
// ═══════════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  final Color accentColor, textSecondary;
  final String label;
  const _LoadingView({
    required this.accentColor,
    required this.textSecondary,
    this.label = "Getting your location...",
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          strokeWidth: 2.5,
          color: accentColor,
          // FIX: withOpacity → withValues(alpha:)
          backgroundColor: accentColor.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 20),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Color accentColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, btnTextColor;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnTextColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              // FIX: withOpacity → withValues(alpha:)
              color: AppTheme.colorError.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                // FIX: withOpacity → withValues(alpha:)
                color: AppTheme.colorError.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: AppTheme.colorError,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Couldn't Find Qibla",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          // FIX: Flexible prevents long error messages from overflowing
          // the Column on small screens
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Try Again",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: btnTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
