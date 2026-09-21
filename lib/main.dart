import 'package:flutter/material.dart';

import 'flora_live_banner.dart';

void main() => runApp(const FloraDemoApp());

/// Minimal demo: `flutter run` shows the banner on a dark ground.
class FloraDemoApp extends StatelessWidget {
  const FloraDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flora Live banner',
      home: Scaffold(
        backgroundColor: const Color(0xFF12102A),
        body: Center(
          child: FloraLiveBanner(
            onStart: () => debugPrint('Start Flora Live tapped'),
          ),
        ),
      ),
    );
  }
}
