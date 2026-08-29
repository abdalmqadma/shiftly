import 'package:flutter/material.dart';
import 'models/work_pattern.dart';
import 'screens/main_shell.dart';
import 'screens/setup_screen.dart';

class ShiftlyApp extends StatefulWidget {
  const ShiftlyApp({super.key});

  @override
  State<ShiftlyApp> createState() => _ShiftlyAppState();
}

class _ShiftlyAppState extends State<ShiftlyApp> {
  WorkPattern? pattern;
  bool editing = false;

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF6D4AFF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shiftly',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.light,
          surface: const Color(0xFFFFFBF7),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF7),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFEDE8FF),
          height: 72,
        ),
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: pattern == null || editing
          ? SetupScreen(onSaved: (value) {
              setState(() {
                pattern = value;
                editing = false;
              });
            })
          : MainShell(
              pattern: pattern!,
              onEditPattern: () => setState(() => editing = true),
            ),
    );
  }
}
