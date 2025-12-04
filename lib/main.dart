import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(DeepSeekApp());
}
