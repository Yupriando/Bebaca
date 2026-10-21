import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/event_logger.dart';
import '../../services/premium_store.dart';
import '../../services/settings_store.dart';
import '../../services/sound_service.dart';
import '../learn/learn_tab.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../stories/stories_page.dart';
import 'app_sidebar.dart';
import 'parental_lock_screen.dart';

/// Kerangka main menu: sidebar (layar lebar) / bottom bar (layar sempit).
/// Halaman dimuat ulang tiap kali tab dibuka, supaya data selalu terbaru.
///
/// Selagi app terbuka: waktu belajar dicatat ke backend tiap 1 menit, dan
/// kontrol orang tua (batas waktu & jam malam) dicek -> layar terkunci bila terlanggar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _timer;
  final _store = SettingsStore.instance;

  static const _pages = <Widget>[
    LearnTab(),
    StoriesPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _startTimer();
    PremiumStore.instance.init();
    EventLogger.instance.log('app_open');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      EventLogger.instance.log('app_open');
      _loadSettings();
      PremiumStore.instance.refresh(); // mis. baru saja dibatalkan di toko
      _startTimer();
      if (mounted) setState(() {}); // jam malam bisa saja sudah tiba
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _timer?.cancel();
      EventLogger.instance.log('app_pause'); // diminimize / pindah aplikasi / layar mati
      EventLogger.instance.flush(); // kirim sisa kejadian sebelum aplikasi ditinggal
    }
  }

  Future<void> _loadSettings() async {
    try {
      await _store.refresh();
    } catch (_) {
      // gagal: pakai salinan terakhir di perangkat
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    // waktu saat layar terkunci tidak dihitung sebagai waktu belajar
    if (_store.lockReason == LockReason.none) {
      EventLogger.instance.log('heartbeat'); // "sedang aktif" untuk Pantau Langsung
      try {
        await _store.addUsage(1);
      } catch (_) {}
    }
    if (mounted) setState(() {}); // cek ulang jam malam
  }

  LockReason? _loggedLock;

  /// Catat saat layar terkunci / terbuka lagi (untuk Pantau Langsung).
  void _logLock(LockReason reason) {
    if (reason == _loggedLock) return;
    final first = _loggedLock == null;
    _loggedLock = reason;
    if (reason != LockReason.none) {
      EventLogger.instance.ui('locked', {'reason': reason.name});
    } else if (!first) {
      EventLogger.instance.ui('unlocked');
    }
  }

  void _select(int i) {
    if (i != _index) {
      SoundService.instance.play(Sfx.tap, volume: 0.5);
      EventLogger.instance.log('tab', {'index': i, 'name': navItems[i].label});
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 700;
      final content = KeyedSubtree(
        key: ValueKey(_index),
        child: _pages[_index],
      );

      final shell = Scaffold(
        body: SafeArea(
          child: wide
              ? Row(children: [
                  AppSidebar(selectedIndex: _index, onSelected: _select),
                  Expanded(child: content),
                ])
              : content,
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  for (final item in navItems)
                    NavigationDestination(
                      icon: NavIcon(item: item, size: 30),
                      label: item.label,
                    ),
                ],
              ),
      );

      // Layar terkunci menutup semuanya (termasuk lesson yang sedang berjalan).
      return AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final reason = _store.lockReason;
          _logLock(reason);
          return Stack(
            children: [
              shell,
              if (reason != LockReason.none)
                Positioned.fill(child: ParentalLockScreen(reason: reason)),
            ],
          );
        },
      );
    });
  }
}
