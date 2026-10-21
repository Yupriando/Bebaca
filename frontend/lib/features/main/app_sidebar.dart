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
  NavItem('Dongeng', 'assets/images/nav_dongeng.png', Icons.auto_stories_rounded),
  NavItem('Profile', 'assets/images/nav_profile.png', Icons.person_rounded),
  NavItem('Settings', 'assets/images/nav_settings.png', Icons.settings_rounded),
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
      errorBuilder: (_, __, ___) =>
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
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.divider, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo_icon.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        size: 48,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Bebaca',
                    style: GoogleFonts.itim(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    )),
              ],
            ),
          ),
          for (var i = 0; i < navItems.length; i++)
            _SidebarTile(
              item: navItems[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarTile(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                NavIcon(item: item),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: GoogleFonts.itim(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? const Color(0xFF1F5F85)
                        : const Color(0xFF808080),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
