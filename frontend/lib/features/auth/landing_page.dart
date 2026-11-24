import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/sky_background.dart';
import '../lesson/widgets/mascot.dart';

/// Halaman awal ala banner: langit berawan, logo besar, "Belajar Baca Jadi Seru!",
/// lalu tombol Buat Akun & Login.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        latar: Latar.masuk,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 760;
              final brand = _Brand(big: wide);
              final actions = SoftCard(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                radius: 32,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Mascot(mood: MascotMood.cheer, size: 96),
                      const SizedBox(height: 10),
                      Text(
                        'Ayo mulai belajar!',
                        style: GoogleFonts.fredoka(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buat akun baru atau masuk dengan akunmu.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: AppColors.hint,
                        ),
                      ),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: 'Buat Akun',
                        height: 56,
                        onPressed:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.register,
                            ),
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: 'Login',
                        height: 56,
                        outlined: true,
                        onPressed:
                            () => Navigator.pushNamed(context, AppRoutes.login),
                      ),
                    ],
                  ),
                ),
              );

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child:
                      wide
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(child: brand),
                              const SizedBox(width: 32),
                              actions,
                            ],
                          )
                          : Column(
                            children: [
                              brand,
                              const SizedBox(height: 28),
                              actions,
                            ],
                          ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final bool big;
  const _Brand({required this.big});

  @override
  Widget build(BuildContext context) {
    final logo = big ? 120.0 : 84.0;
    return Column(
      crossAxisAlignment:
          big ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(logo * 0.26),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x331C5FC7),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(logo * 0.22),
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  width: logo,
                  height: logo,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            _Wordmark(size: big ? 84 : 60),
          ],
        ),
        const SizedBox(height: 18),
        // label kuning miring, seperti di banner
        Transform.rotate(
          angle: -0.04,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: big ? 26 : 18,
              vertical: big ? 12 : 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.sun,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: AppColors.sunDark, offset: Offset(0, 5)),
              ],
            ),
            child: Text(
              'Belajar Baca Jadi Seru!',
              style: GoogleFonts.fredoka(
                fontSize: big ? 36 : 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'Aplikasi belajar membaca untuk anak dengan pembelajaran interaktif, '
            'latihan menulis, dan dongeng edukatif.',
            textAlign: big ? TextAlign.start : TextAlign.center,
            // teks gelap: tetap terbaca jelas di atas langit yang terang
            style: GoogleFonts.fredoka(
              fontSize: big ? 21 : 17,
              color: AppColors.textDark.withAlpha(220),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tulisan "Bebaca" putih tebal dengan garis tepi biru tua (seperti logo di banner).
class _Wordmark extends StatelessWidget {
  final double size;
  const _Wordmark({required this.size});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    return Stack(
      children: [
        Text(
          'Bebaca',
          style: style.copyWith(
            foreground:
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = size * 0.14
                  ..strokeJoin = StrokeJoin.round
                  ..color = AppColors.primaryDark,
          ),
        ),
        Text('Bebaca', style: style.copyWith(color: Colors.white)),
      ],
    );
  }
}
