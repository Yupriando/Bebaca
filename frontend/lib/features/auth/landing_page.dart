import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/primary_button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          final logo = ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.asset(
              'assets/images/logo.png',
              width: isWide ? 360 : 220,
              height: isWide ? 360 : 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.menu_book_rounded,
                size: isWide ? 260 : 160,
                color: const Color(0xFF50A5DB),
              ),
            ),
          );

          final actions = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Belajar baca yang menyenangkan',
                  textAlign: TextAlign.center,
                  style: AppTheme.title(context, size: isWide ? 36 : 28),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Buat Akun',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.register),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Login',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.login),
                ),
              ],
            ),
          );

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [logo, actions],
                    )
                  : Column(
                      children: [logo, const SizedBox(height: 32), actions],
                    ),
            ),
          );
        },
      ),
    );
  }
}
