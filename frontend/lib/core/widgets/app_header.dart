import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'primary_button.dart';

/// Header Bebaca: logo + teks di kiri, tombol aksi opsional di kanan.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const AppHeader({super.key, this.actionLabel, this.onActionPressed});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 3)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo_icon.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.menu_book_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Bebaca',
              style: GoogleFonts.itim(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            if (actionLabel != null)
              PrimaryButton(
                label: actionLabel!,
                onPressed: onActionPressed,
                width: 130,
                height: 44,
                fontSize: 18,
              ),
          ],
        ),
      ),
    );
  }
}
