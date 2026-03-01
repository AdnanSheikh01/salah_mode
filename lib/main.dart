import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/auth/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salah Mode',
      home: SalahAuthScreen(),
    );
  }
}
