import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Tombol pil ala banner Bebaca. [outlined] = tombol putih bergaris tepi (mis. "Login").
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final double fontSize;
  final bool isLoading;
  final Color color;
  final bool outlined;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 52,
    this.fontSize = 22,
    this.isLoading = false,
    this.color = AppColors.primary,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? color : AppColors.white;
    final enabled = onPressed != null && !isLoading;
    final content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: fontSize + 4),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: GoogleFonts.fredoka(fontSize: fontSize, fontWeight: FontWeight.w600, color: fg),
                ),
              ),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        // "kaki" tombol: bayangan tebal di bawah, seperti tombol di banner
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height),
          boxShadow: enabled && !outlined
              ? [BoxShadow(color: Color.lerp(color, Colors.black, 0.25)!, offset: const Offset(0, 4))]
              : null,
        ),
        child: Material(
          color: outlined ? Colors.white : (enabled ? color : color.withAlpha(150)),
          shape: StadiumBorder(
            side: outlined ? BorderSide(color: color, width: 2.5) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
