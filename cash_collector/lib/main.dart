import 'package:cash_collector/screens/splash_screen.dart';
import 'package:flutter/material.dart';

// Define the app name
const String appName = 'Cash Collector';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      home: const LaunchPage(), // or LaunchPage() if defined
    );
  }
}
