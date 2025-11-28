import 'package:flutter/material.dart';
import 'main_scaffold.dart';

class DeepSeekApp extends StatelessWidget {
  const DeepSeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryBlue = Colors.blue.shade700;
    return MaterialApp(
      title: 'DeepSeek - Price Compare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black),
        ),
      ),
      initialRoute: '/',
      routes: {'/': (_) => MainScaffold()},
    );
  }
}
