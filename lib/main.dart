import 'package:flutter/widgets.dart';

import 'app.dart';
import 'state/tracker_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = TrackerController();
  await controller.initialize();

  runApp(TransitPulseApp(controller: controller));
}
