import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/config_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/consumption_screen.dart';
import 'screens/splash_screen.dart';
import 'services/permissions_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Solicita e aguarda permissões BLE
  bool granted = await PermissionsService.requestBlePermissions();

  if (granted) {
    print("✅ Permissões BLE concedidas!");
  } else {
    print("⚠️ Permissões BLE negadas");
  }

  // 2) Agora inicia o app
  runApp(WaterSenseApp());
}

class WaterSenseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaterSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF0D1B2A),
        scaffoldBackgroundColor: Color(0xFF0D1B2A),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF0D1B2A),
          secondary: Color(0xFF1B263B),
          surface: Color(0xFF1B263B),
          background: Color(0xFF0D1B2A),
          onPrimary: Colors.white,
          onSecondary: Colors.white70,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0D1B2A),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1B263B),
          selectedItemColor: Colors.lightBlueAccent,
          unselectedItemColor: Colors.white70,
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/config': (context) => ConfigScreen(),
        '/home': (context) => HomeScreen(),
        '/history': (context) => HistoryScreen(),
        '/consumption': (context) => ConsumptionScreen(),
      },
    );
  }
}
