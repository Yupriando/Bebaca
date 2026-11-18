import 'package:flutter/material.dart';
import '../../core/widgets/sky_background.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String _date(DateTime? d) =>
      d == null
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
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text(
                    'Ambil foto',
                    style: TextStyle(fontSize: 20),
                  ),
                  onTap: () => Navigator.pop(ctx, _AvatarAction.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text(
                    'Pilih dari galeri',
                    style: TextStyle(fontSize: 20),
                  ),
                  onTap: () => Navigator.pop(ctx, _AvatarAction.gallery),
                ),
                if (p.avatarUrl != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Hapus foto',
                      style: TextStyle(fontSize: 20, color: Colors.redAccent),
                    ),
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
          source:
              action == _AvatarAction.camera
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
      _snack(
        action == _AvatarAction.remove
            ? 'Foto dihapus'
            : 'Foto profil diperbarui',
      );
      _reload();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) {
        _snack('Tidak bisa mengambil foto. Periksa izin kamera/galeri.');
      }
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

        final info = Column(
          children: [
            for (final r in rows) _InfoRow(label: r.$1, value: r.$2),
            AnimatedBuilder(
              animation: PremiumStore.instance,
              builder:
                  (context, _) => _InfoRow(
                    label: 'Langganan',
                    value: PremiumStore.instance.status.label,
                  ),
            ),
          ],
        );
        // kartu kiri: foto, nama, hari beruntun | kartu kanan: data profil (gaya banner)
        final hero = SoftCard(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(
                url: p.avatarUrl,
                busy: _uploading,
                onTap: _uploading ? null : () => _changeAvatar(p),
              ),
              const SizedBox(height: 14),
              Text(
                p.nama,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDE0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '🔥 ${p.hariBerturut} hari beruntun',
                  style: GoogleFonts.fredoka(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Edit Profil',
                icon: Icons.edit_rounded,
                onPressed: () => _edit(p),
                width: 220,
              ),
            ],
          ),
        );
        final details = SoftCard(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
          child: info,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth < 720) {
                    return Column(
                      children: [hero, const SizedBox(height: 16), details],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 300, child: hero),
                      const SizedBox(width: 18),
                      Expanded(child: details),
                    ],
                  );
                },
              ),
            ),
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

  Widget _placeholder() =>
      const Center(child: Icon(Icons.person, size: 130, color: Colors.white));

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
                color: Color(0xFFBFD9F7),
              ),
              child: ClipOval(
                child:
                    url == null
                        ? _placeholder()
                        : Image.network(
                          url!,
                          width: _size,
                          height: _size,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                          loadingBuilder:
                              (context, child, progress) =>
                                  progress == null
                                      ? child
                                      : const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
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
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 24,
                ),
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
              label,
              style: GoogleFonts.fredoka(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.hint,
              ),
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
