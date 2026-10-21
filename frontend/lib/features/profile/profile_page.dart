import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_body.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/premium_store.dart';
import '../../services/profile_service.dart';
import 'edit_profile_sheet.dart';

enum _AvatarAction { camera, gallery, remove }

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _service = ProfileService();
  late Future<UserProfile> _future = _service.getProfile();
  bool _uploading = false;

  void _reload() {
    setState(() {
      _future = _service.getProfile();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _date(DateTime? d) => d == null
      ? '-'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _edit(UserProfile p) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => EditProfileSheet(profile: p),
    );
    if (saved == true && mounted) {
      _snack('Profil diperbarui');
      _reload();
    }
  }

  Future<void> _changeAvatar(UserProfile p) async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Ambil foto', style: TextStyle(fontSize: 20)),
              onTap: () => Navigator.pop(ctx, _AvatarAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari galeri', style: TextStyle(fontSize: 20)),
              onTap: () => Navigator.pop(ctx, _AvatarAction.gallery),
            ),
            if (p.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Hapus foto',
                    style: TextStyle(fontSize: 20, color: Colors.redAccent)),
                onTap: () => Navigator.pop(ctx, _AvatarAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null) return;

    try {
      if (action == _AvatarAction.remove) {
        setState(() => _uploading = true);
        await _service.removeAvatar();
      } else {
        final picked = await ImagePicker().pickImage(
          source: action == _AvatarAction.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          // dikecilkan di perangkat dulu: unggahan cepat & hemat kuota
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (picked == null) return; // dibatalkan
        setState(() => _uploading = true);
        await _service.uploadAvatar(await picked.readAsBytes(), picked.name);
      }
      if (!mounted) return;
      _snack(action == _AvatarAction.remove ? 'Foto dihapus' : 'Foto profil diperbarui');
      _reload();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('Tidak bisa mengambil foto. Periksa izin kamera/galeri.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<UserProfile>(
      future: _future,
      builder: (context, p) {
        final rows = <(String, String)>[
          ('Nama', p.nama),
          ('Tanggal lahir', _date(p.tanggalLahir)),
          ('Umur', p.umur == null ? '-' : '${p.umur} tahun'),
          ('Tingkat kesulitan', p.tingkatKesulitan),
          ('Hari belajar berturut-turut', '${p.hariBerturut} hari'),
          ('Materi terakhir', p.materiTerakhir ?? 'Belum ada'),
        ];

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 28),
              _Avatar(
                url: p.avatarUrl,
                busy: _uploading,
                onTap: _uploading ? null : () => _changeAvatar(p),
              ),
              const SizedBox(height: 28),
              const Divider(height: 1, color: Colors.black87),
              const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        for (final r in rows) _InfoRow(label: r.$1, value: r.$2),
                        AnimatedBuilder(
                          animation: PremiumStore.instance,
                          builder: (context, _) => _InfoRow(
                            label: 'Langganan',
                            value: PremiumStore.instance.status.label,
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Edit Profil',
                          onPressed: () => _edit(p),
                          width: 260,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final bool busy;
  final VoidCallback? onTap;
  const _Avatar({required this.url, required this.busy, required this.onTap});

  static const _size = 170.0;

  Widget _placeholder() => const Center(
        child: Icon(Icons.person, size: 130, color: Colors.white),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _size,
              height: _size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF9E9E9E),
              ),
              child: ClipOval(
                child: url == null
                    ? _placeholder()
                    : Image.network(
                        url!,
                        width: _size,
                        height: _size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(color: Colors.white)),
                      ),
              ),
            ),
            if (busy)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black38,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            // lencana kamera: tanda bahwa foto bisa diganti
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.photo_camera_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '$label :',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Container(
              // tinggi menyesuaikan isi: teks panjang (mis. "Materi terakhir") turun ke baris baru
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 22, color: AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
