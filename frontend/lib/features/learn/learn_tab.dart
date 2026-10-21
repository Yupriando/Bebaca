import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'learn_page.dart';

/// Tab Belajar punya Navigator sendiri: lesson dibuka DI DALAM tab ini,
/// jadi sidebar / bottom bar tetap terlihat (sesuai desain).
class LearnTab extends StatefulWidget {
  const LearnTab({super.key});

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  final _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = _navKey.currentState;
        // tombol Back sistem: tutup lesson dulu; kalau sudah di daftar lesson -> keluar app
        if (nav != null && await nav.maybePop()) return;
        SystemNavigator.pop();
      },
      child: Navigator(
        key: _navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => const LearnPage(),
        ),
      ),
    );
  }
}
