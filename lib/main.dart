import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/wallet_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const CreditCardVaultApp());
}

class CreditCardVaultApp extends StatelessWidget {
  const CreditCardVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Vault',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Color(0xFF10B981),
          surface: Colors.white,
          onSurface: Colors.black87,
          error: Colors.redAccent,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        primaryColor: Colors.white,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E1E24),
          onSurface: Colors.white,
          error: Colors.redAccent,
        ),
        useMaterial3: true,
      ),
      home: const WalletScreen(),
    );
  }
}
