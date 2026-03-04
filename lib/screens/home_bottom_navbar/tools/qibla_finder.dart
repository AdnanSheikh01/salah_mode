import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  double? _deviceHeading;
  double? _qiblaDirection;
  bool _loading = true;

  StreamSubscription<CompassEvent>? _compassSub;
  bool _aligned = false;

  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _qiblaDirection = _calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );
      _compassSub = FlutterCompass.events?.listen((event) async {
        if (!mounted) return;

        final heading = event.heading;
        if (heading == null) return;

        final diff = (_qiblaDirection! - heading).abs();
        final isNowAligned = diff < 5 || diff > 355;

        if (isNowAligned && !_aligned) {
          _aligned = true;
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 200);
          }
        } else if (!isNowAligned) {
          _aligned = false;
        }

        setState(() {
          _deviceHeading = heading;
          _loading = false;
        });
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  double _calculateQiblaDirection(double lat, double lng) {
    final kaabaLatRad = _degToRad(_kaabaLat);
    final kaabaLngRad = _degToRad(_kaabaLng);
    final userLatRad = _degToRad(lat);
    final userLngRad = _degToRad(lng);

    final dLng = kaabaLngRad - userLngRad;

    final y = sin(dLng);
    final x = cos(userLatRad) * tan(kaabaLatRad) - sin(userLatRad) * cos(dLng);

    final bearing = atan2(y, x);
    return (_radToDeg(bearing) + 360) % 360;
  }

  double _degToRad(double deg) => deg * pi / 180;
  double _radToDeg(double rad) => rad * 180 / pi;

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Qibla Finder",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: _loading || _deviceHeading == null || _qiblaDirection == null
            ? CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🌐 Compass Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(.4),
                            width: 2,
                          ),
                        ),
                      ),

                      // 🧭 Rotating needle
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end:
                              ((_qiblaDirection! - _deviceHeading!) *
                                  pi /
                                  180) *
                              -1,
                        ),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, angle, child) {
                          return Transform.rotate(angle: angle, child: child);
                        },
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _aligned
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _aligned
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(.4)
                                    : Colors.black54,
                                blurRadius: 30,
                                spreadRadius: 3,
                              ),
                            ],
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(.9),
                                Theme.of(context).colorScheme.surface,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.navigation,
                              color: Theme.of(context).colorScheme.primary,
                              size: 90,
                            ),
                          ),
                        ),
                      ),

                      // 🕌 Kaaba center marker
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 🔢 Degree text
                  Text(
                    "${_qiblaDirection!.toStringAsFixed(1)}° to Qibla",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🎯 Status text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _aligned
                          ? "Perfectly aligned with Kaaba 🕌"
                          : "Move phone slowly to align",
                      key: ValueKey(_aligned),
                      style: TextStyle(
                        color: _aligned
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 📍 Calibration hint
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(.6),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "If direction is inaccurate, move phone in a figure-8 motion",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(.6),
                              fontSize: 12,
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
