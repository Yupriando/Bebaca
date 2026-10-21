import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Kolom isian Bebaca. Jika [obscureText] (password), ada tombol mata
/// untuk menampilkan / menyembunyikan isinya.
class AppTextField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      style: GoogleFonts.itim(fontSize: 22, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: widget.obscureText
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: _hidden ? 'Tampilkan password' : 'Sembunyikan password',
                  iconSize: 28,
                  color: AppColors.hint,
                  icon: Icon(_hidden
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              )
            : null,
        hintStyle: GoogleFonts.itim(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.hint,
        ),
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
