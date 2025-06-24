import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart' as intl;
import 'firebase_options.dart';
import 'utils/navigation.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

const Color primaryColor = Color(0xFFF7F7F7);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await intl.initializeDateFormatting('da');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RoomMatchApp());
}

class RoomMatchApp extends StatelessWidget {
  const RoomMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'RoomMatch',
      theme: _theme(),
      debugShowCheckedModeBanner: false,
      home: const MainScreen(initialIndex: 0),
    );
  }

  ThemeData _theme() {
    return ThemeData(
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
