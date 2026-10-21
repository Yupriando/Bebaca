import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _umurC = TextEditingController();
  final _namaC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _umurC.dispose();
    _namaC.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await _auth.register(
      umur: int.parse(_umurC.text.trim()),
      nama: _namaC.text.trim(),
      email: _emailC.text.trim(),
      password: _passC.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Akun berhasil dibuat! Silakan login.'
            : (result.message ?? 'Gagal membuat akun')),
      ),
    );
    if (result.success) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        actionLabel: 'Login',
        onActionPressed: () =>
            Navigator.pushReplacementNamed(context, AppRoutes.login),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Buatlah Profile Anda',
                      textAlign: TextAlign.center,
                      style: AppTheme.title(context, size: 34)),
                  const SizedBox(height: 28),
                  AppTextField(
                    hint: 'Umur',
                    controller: _umurC,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Masukkan umur yang valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    hint: 'Nama',
                    controller: _namaC,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    hint: 'Email',
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Email tidak valid'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    hint: 'Password',
                    controller: _passC,
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Minimal 6 karakter'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Buat Akun',
                    onPressed: _submit,
                    isLoading: _loading,
                    width: 320,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
