import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await _auth.login(
      email: _emailC.text.trim(),
      password: _passC.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.main, (route) => false);
    } else {
      _showMessage(result.message ?? 'Login gagal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        actionLabel: 'Sign-Up',
        onActionPressed: () =>
            Navigator.pushReplacementNamed(context, AppRoutes.register),
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
                  Text('Log in',
                      style: AppTheme.title(context, size: 34)
                          .copyWith(color: Colors.black)),
                  const SizedBox(height: 28),
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
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'MASUK',
                    onPressed: _login,
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
