import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/profile_service.dart';

/// Lembar edit profil: nama, tanggal lahir, umur.
/// - Tanggal lahir diisi  -> umur dihitung otomatis (tidak bisa diketik).
/// - Tanggal lahir kosong -> umur diisi manual.
/// Ditutup dengan hasil `true` jika berhasil disimpan.
class EditProfileSheet extends StatefulWidget {
  final UserProfile profile;
  const EditProfileSheet({super.key, required this.profile});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama =
      TextEditingController(text: widget.profile.nama);
  late final TextEditingController _umur =
      TextEditingController(text: widget.profile.umur?.toString() ?? '');
  late DateTime? _birth = widget.profile.tanggalLahir;

  final _service = ProfileService();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nama.dispose();
    _umur.dispose();
    super.dispose();
  }

  static int _ageFrom(DateTime d) {
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    return age;
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 6, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
    );
    if (picked != null) {
      setState(() {
        _birth = picked;
        _umur.text = _ageFrom(picked).toString();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.updateProfile(
        nama: _nama.text.trim(),
        tanggalLahir: _birth,
        clearTanggalLahir: _birth == null && widget.profile.tanggalLahir != null,
        umur: _birth == null ? int.parse(_umur.text.trim()) : null,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
      );

  /// Kotak berbentuk sama dengan AppTextField, tetapi diketuk (bukan diketik).
  Widget _tapBox({required String text, required bool placeholder, VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: placeholder ? FontWeight.bold : FontWeight.normal,
                  color: placeholder ? AppColors.hint : AppColors.textDark,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final birth = _birth;

    return Padding(
      // naik mengikuti keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Edit Profil',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                  ),
                  const SizedBox(height: 18),
                  _label('Nama'),
                  AppTextField(
                    hint: 'Nama',
                    controller: _nama,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Nama wajib diisi';
                      if (t.length > 60) return 'Nama terlalu panjang';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Tanggal lahir'),
                  _tapBox(
                    text: birth == null ? 'Pilih tanggal lahir' : _fmt(birth),
                    placeholder: birth == null,
                    onTap: _pickDate,
                    trailing: birth == null
                        ? const Icon(Icons.calendar_month_rounded, color: AppColors.hint)
                        : IconButton(
                            tooltip: 'Hapus tanggal lahir',
                            icon: const Icon(Icons.close_rounded, color: AppColors.hint),
                            onPressed: () => setState(() => _birth = null),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _label('Umur'),
                  if (birth != null)
                    _tapBox(
                      text: '${_ageFrom(birth)} tahun',
                      placeholder: false,
                      trailing: const Text('otomatis',
                          style: TextStyle(fontSize: 16, color: AppColors.hint)),
                    )
                  else
                    AppTextField(
                      hint: 'Umur',
                      controller: _umur,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1 || n > 120) {
                          return 'Masukkan umur 1 - 120';
                        }
                        return null;
                      },
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _saving ? null : () => Navigator.pop(context, false),
                          child: const Text('Batal', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: 'Simpan',
                          onPressed: _save,
                          isLoading: _saving,
                        ),
                      ),
                    ],
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
