import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../../services/event_logger.dart';
import '../../services/settings_store.dart';

/// "Gerbang orang tua": PIN 4 angka (menggantikan soal penjumlahan, yang lama-lama
/// bisa dijawab anak). Dipakai sebelum mengubah kontrol orang tua, membuka layar
/// terkunci, dan membuka Bebaca Premium. Mengembalikan true jika lolos.
///
/// - Belum punya PIN -> diminta membuat PIN dulu (wajib password akun).
/// - Lupa PIN        -> buat PIN baru dengan password akun.
Future<bool> showParentalGate(BuildContext context) async {
  final store = SettingsStore.instance;
  if (!store.loaded) {
    try {
      await store.refresh(); // perlu tahu apakah PIN sudah dibuat
    } catch (_) {}
  }
  if (!context.mounted) return false;

  if (!store.value.hasParentPin) {
    return showSetParentPin(context, firstTime: true);
  }

  EventLogger.instance.ui('parent_gate');
  final result = await showDialog<_PinResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PinDialog(),
  );
  if (result == _PinResult.forgot && context.mounted) {
    return showSetParentPin(context, forgot: true);
  }
  return result == _PinResult.ok;
}

/// Buat / ganti PIN orang tua. true jika berhasil disimpan.
Future<bool> showSetParentPin(
  BuildContext context, {
  bool firstTime = false,
  bool forgot = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SetPinDialog(firstTime: firstTime, forgot: forgot),
  );
  return ok == true;
}

enum _PinResult { ok, cancel, forgot }

// ================================================================ masukkan PIN

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _checking = false;
  String? _error;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _tap(String digit) {
    if (_checking || _pin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) _check();
  }

  void _backspace() {
    if (_checking || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      await SettingsStore.instance.verifyParentPin(_pin);
      if (mounted) Navigator.pop(context, _PinResult.ok);
    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      setState(() {
        _checking = false;
        _pin = '';
        _error = e.statusCode == 403 ? 'PIN salah, coba lagi' : e.message;
        if (e.statusCode == 403) EventLogger.instance.ui('pin_wrong');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Khusus orang tua', textAlign: TextAlign.center),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan PIN orang tua',
                style: TextStyle(fontSize: 18, color: AppColors.hint)),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) => Transform.translate(
                offset: Offset(sin(_shake.value * pi * 6) * 10 * (1 - _shake.value), 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length ? AppColors.primary : Colors.transparent,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 30,
              child: Center(
                child: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(_error ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 15)),
              ),
            ),
            _Keypad(onDigit: _tap, onBackspace: _backspace),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context, _PinResult.forgot),
          child: const Text('Lupa PIN?'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _PinResult.cancel),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const _Keypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback? onTap) => Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: onTap == null ? Colors.transparent : const Color(0xFFF0F4F8),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(width: 68, height: 68, child: Center(child: child)),
            ),
          ),
        );
    Widget digit(String d) => key(
          Text(d,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          () => onDigit(d),
        );

    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final d in row) digit(d),
          ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          key(const SizedBox.shrink(), null),
          digit('0'),
          key(const Icon(Icons.backspace_outlined, color: AppColors.textDark),
              onBackspace),
        ]),
      ],
    );
  }
}

// ================================================================ buat / ganti PIN

class _SetPinDialog extends StatefulWidget {
  final bool firstTime;
  final bool forgot;
  const _SetPinDialog({required this.firstTime, required this.forgot});

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passC = TextEditingController();
  final _pinC = TextEditingController();
  final _pin2C = TextEditingController();
  bool _hidePass = true;
  bool _hidePin = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _passC.dispose();
    _pinC.dispose();
    _pin2C.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SettingsStore.instance
          .setParentPin(pin: _pinC.text, password: _passC.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN orang tua tersimpan')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  InputDecoration _decoration(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
        suffixIcon: suffix,
      );

  /// Satu tombol mata untuk kedua kolom PIN (PIN baru & ulangi PIN).
  Widget _pinEye() => IconButton(
        tooltip: _hidePin ? 'Tampilkan PIN' : 'Sembunyikan PIN',
        icon: Icon(_hidePin ? Icons.visibility_rounded : Icons.visibility_off_rounded),
        onPressed: () => setState(() => _hidePin = !_hidePin),
      );

  @override
  Widget build(BuildContext context) {
    final title = widget.firstTime
        ? 'Buat PIN orang tua'
        : widget.forgot
            ? 'Atur ulang PIN'
            : 'Ganti PIN orang tua';
    final intro = widget.firstTime
        ? 'Buat PIN 4 angka untuk membuka pengaturan orang tua dan Bebaca Premium. '
            'Masukkan password akun Bebaca untuk memastikan ini orang tua.'
        : 'Masukkan password akun Bebaca, lalu buat PIN 4 angka yang baru.';

    String? pinRule(String? v) =>
        RegExp(r'^\d{4}$').hasMatch(v ?? '') ? null : 'PIN harus 4 angka';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(intro, style: const TextStyle(fontSize: 16, color: AppColors.hint)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passC,
                  obscureText: _hidePass,
                  decoration: _decoration(
                    'Password akun',
                    suffix: IconButton(
                      icon: Icon(_hidePass
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded),
                      onPressed: () => setState(() => _hidePass = !_hidePass),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pinC,
                  obscureText: _hidePin,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration('PIN baru (4 angka)', suffix: _pinEye()),
                  validator: pinRule,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pin2C,
                  obscureText: _hidePin,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration('Ulangi PIN', suffix: _pinEye()),
                  validator: (v) => v != _pinC.text ? 'PIN tidak sama' : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 15)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan PIN'),
        ),
      ],
    );
  }
}
