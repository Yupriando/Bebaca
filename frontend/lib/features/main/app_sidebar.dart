import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class NavItem {
  final String label;
  final String asset; // taruh gambar di assets/images/
  final IconData fallback;
  const NavItem(this.label, this.asset, this.fallback);
}

/// Daftar menu utama. Urutan harus sama dengan halaman di MainShell.
const navItems = [
  NavItem('Belajar', 'assets/images/nav_belajar.png', Icons.school_rounded),
  NavItem(
    'Dongeng',
    'assets/images/nav_dongeng.png',
    Icons.auto_stories_rounded,
  ),
  NavItem('Profil', 'assets/images/nav_profile.png', Icons.person_rounded),
  NavItem('Pengaturan', 'assets/images/nav_settings.png', Icons.settings_rounded),
];

class NavIcon extends StatelessWidget {
  final NavItem item;
  final double size;
  const NavIcon({super.key, required this.item, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      item.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder:
          (_, __, ___) =>
              Icon(item.fallback, size: size * 0.8, color: AppColors.primary),
    );
  }
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // HP dalam posisi landscape: layar pendek -> sidebar lebih ringkas
    final compact = MediaQuery.of(context).size.height < 560;
    // panel putih membulat yang "melayang" di atas langit (gaya banner)
    return Container(
      width: compact ? 216 : 256,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x221C5FC7), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: compact
                  ? const EdgeInsets.fromLTRB(16, 14, 10, 10)
                  : const EdgeInsets.fromLTRB(18, 20, 12, 18),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo_icon.png',
                      width: compact ? 40 : 50,
                      height: compact ? 40 : 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Bebaca',
                    style: GoogleFonts.fredoka(
                      fontSize: compact ? 28 : 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < navItems.length; i++)
              _SidebarTile(
                item: navItems[i],
                selected: i == selectedIndex,
                compact: compact,
                onTap: () => onSelected(i),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = compact ? 34.0 : 44.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 3 : 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 6 : 9),
              child: Row(
                children: [
                  Container(
                    width: icon + 10,
                    height: icon + 10,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: NavIcon(item: item, size: icon),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontSize: compact ? 21 : 25,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.hint,
                      ),
                    ),
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
