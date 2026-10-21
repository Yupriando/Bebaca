import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/api_client.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Sesi habis (refresh token gagal) -> kembali ke halaman awal.
  ApiClient.onSessionExpired = () {
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(AppRoutes.landing, (route) => false);
  };
  runApp(const BebacaApp());
}

class BebacaApp extends StatelessWidget {
  const BebacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bebaca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
