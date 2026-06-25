import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/tracker_controller.dart';
import 'theme/app_theme.dart';

class TransitPulseApp extends StatelessWidget {
  const TransitPulseApp({
    super.key,
    required this.controller,
  });

  final TrackerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transit Pulse',
      theme: AppTheme.theme(),
      home: HomeScreen(controller: controller),
    );
  }
}
