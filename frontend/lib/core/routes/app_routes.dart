import 'package:flutter/material.dart';
import '../../features/auth/landing_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/main/main_shell.dart';
import '../../features/splash/splash_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const landing = '/';
  static const register = '/register';
  static const login = '/login';
  static const main = '/main';

  // Tambahkan halaman baru (mis. home) di sini.
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashPage(),
    landing: (_) => const LandingPage(),
    register: (_) => const RegisterPage(),
    login: (_) => const LoginPage(),
    main: (_) => const MainShell(),
  };
}
