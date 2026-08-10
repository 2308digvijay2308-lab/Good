import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// ============================================================================
///  PROJECT JARVIS — APPLICATION ENTRY POINT
/// ----------------------------------------------------------------------------
///  Boots the app with a premium Material 3 dark theme and launches the
///  single-screen voice-assistant experience.
/// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Material 3 dark color scheme (green accent, deep space bg) --------
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E676),
      brightness: Brightness.dark,
      primary: const Color(0xFF00E676),
      onPrimary: const Color(0xFF00210E),
      secondary: const Color(0xFF29B6F6),
      surface: const Color(0xFF0B0F14),
      surfaceContainerHighest: const Color(0xFF1E2732),
    );

    return MaterialApp(
      title: 'PROJECT JARVIS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12171E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF12171E),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1E2732),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
      ),
      home: const HomeScreen(),
    );
  }
}
