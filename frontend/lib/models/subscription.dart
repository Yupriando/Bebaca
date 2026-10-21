enum PremiumPlan { monthly, yearly }

/// Status Bebaca Premium milik akun ini (dihitung server).
class SubscriptionStatus {
  final bool isPremium;
  final PremiumPlan? plan;
  final DateTime? expiresAt;
  final bool autoRenew;
  final String? platform; // manual = simulasi / hadiah

  const SubscriptionStatus({
    this.isPremium = false,
    this.plan,
    this.expiresAt,
    this.autoRenew = false,
    this.platform,
  });

  static const free = SubscriptionStatus();

  factory SubscriptionStatus.fromJson(Map<String, dynamic> j) => SubscriptionStatus(
        isPremium: j['isPremium'] == true,
        plan: PremiumPlan.values.where((p) => p.name == j['plan']).firstOrNull,
        expiresAt: j['expiresAt'] == null
            ? null
            : DateTime.tryParse(j['expiresAt'] as String)?.toLocal(),
        autoRenew: j['autoRenew'] == true,
        platform: j['platform'] as String?,
      );

  /// mis. "12 November 2026"
  static String formatDate(DateTime d) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Teks singkat untuk halaman Profil.
  String get label {
    if (!isPremium) return 'Gratis';
    final until = expiresAt == null ? '' : ' s.d. ${formatDate(expiresAt!)}';
    return 'Premium$until';
  }
}
