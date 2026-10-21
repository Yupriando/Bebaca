class UserProfile {
  final String nama;
  final String? email;
  final DateTime? tanggalLahir;
  final int? umur;
  final String tingkatKesulitan;
  final int hariBerturut;
  final String? materiTerakhir;
  final String? avatarUrl;

  const UserProfile({
    required this.nama,
    this.email,
    required this.tanggalLahir,
    required this.umur,
    required this.tingkatKesulitan,
    required this.hariBerturut,
    required this.materiTerakhir,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        nama: (j['nama'] as String?) ?? '',
        email: j['email'] as String?,
        tanggalLahir: j['tanggalLahir'] != null
            ? DateTime.tryParse(j['tanggalLahir'] as String)
            : null,
        umur: j['umur'] as int?,
        tingkatKesulitan: (j['tingkatKesulitan'] as String?) ?? 'Mudah',
        hariBerturut: (j['hariBerturut'] as int?) ?? 0,
        materiTerakhir: j['materiTerakhir'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
      );
}
