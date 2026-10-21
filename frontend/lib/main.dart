import 'package:flutter/material.dart';
import 'core/config/app_orientation.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/adaptive_scale.dart';
import 'services/api_client.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await applyAppSystemUi(); // landscape + layar penuh

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
      // HP s.d. tablet: tampilan diperkecil proporsional di layar pendek agar semua terlihat
      builder: (context, child) => AdaptiveScale(child: child!),
    );
  }
}
