import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  final _locationStreamController = FlutterQiblah.qiblahStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0D1B2A),
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          "Qibla Compass",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff1B263B),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _checkLocationStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data == false) {
              return _locationErrorWidget();
            }

            return _buildCompass();
          },
        ),
      ),
    );
  }

  Future<bool> _checkLocationStatus() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Widget _locationErrorWidget() {
    return const Center(
      child: Text(
        "Location permission required to find Qibla",
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCompass() {
    return StreamBuilder<QiblahDirection>(
      stream: _locationStreamController,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final qiblahDirection = snapshot.data!;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 🧭 Compass
              Stack(
                alignment: Alignment.center,
                children: [
                  // Compass background
                  Image.asset('assets/compass.png', width: 280),

                  // Qibla needle
                  Transform.rotate(
                    angle: (qiblahDirection.qiblah * (math.pi / 180) * -1),
                    child: Image.asset('assets/needle.png', width: 150),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Text(
                "${qiblahDirection.qiblah.toStringAsFixed(2)}°",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Point the needle towards Kaaba",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}
