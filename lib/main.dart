import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/wallet_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Set system UI overlay styling for a seamless dark mode look
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0F12),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
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
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        primaryColor: Colors.white,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E1E24),
          error: Colors.redAccent,
        ),
        useMaterial3: true,
      ),
      home: const WalletScreen(),
    );
  }
}
