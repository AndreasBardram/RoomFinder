import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

/// A global key if you ever need to show SnackBars from anywhere.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// The primary color you used in the previous project.
const Color primaryColor = Color(0xFFF7F7F7);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RoomMatchApp());
}

class RoomMatchApp extends StatelessWidget {
  const RoomMatchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'RoomMatch',
      theme: _buildThemeData(),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      // Same color scheme logic from your previous project:
      primaryColor: primaryColor,
      scaffoldBackgroundColor: primaryColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.black,
        secondary: primaryColor,
        onSecondary: Colors.black,
        surface: primaryColor,
        onSurface: Colors.black,
        error: Colors.red,
        onError: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
