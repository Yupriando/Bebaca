/// Gambar untuk kata di lesson Kata & Kalimat (benda yang mudah dikenali balita).
/// Kata yang tidak ada di sini tetap bisa dipakai, hanya tanpa gambar.
const wordPictures = <String, String>{
  'ibu': '👩',
  'dadu': '🎲',
  'gigi': '🦷',
  'baca': '📖',
  'dua': '✌️',
  'cuci': '🧼',
  'bola': '⚽',
  'buku': '📚',
  'kuda': '🐴',
  'kaki': '🦶',
  'mata': '👀',
  'baju': '👕',
  'madu': '🍯',
  'lima': '🖐️',
  'kue': '🍰',
  'nasi': '🍚',
  'roti': '🍞',
  'susu': '🥛',
  'sapi': '🐄',
  'rusa': '🦌',
  'topi': '🧢',
  'kopi': '☕',
  'pita': '🎀',
  'sate': '🍢',
  'sepatu': '👟',
  'sepeda': '🚲',
  'boneka': '🧸',
  'kelapa': '🥥',
  'kereta': '🚂',
  'celana': '👖',
  'kucing': '🐱',
  'ikan': '🐟',
  'apel': '🍎',
  'pisang': '🍌',
  'rumah': '🏠',
  'bunga': '🌸',
};

/// Gambar untuk kata atau kalimat: kata benda terakhir yang punya gambar
/// ("Mama baca buku." -> buku).
String? pictureFor(String text) {
  final words = text
      .toLowerCase()
      .replaceAll('-', '')
      .replaceAll(RegExp(r'[^a-z\s]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  for (final w in words.reversed) {
    final p = wordPictures[w];
    if (p != null) return p;
  }
  return null;
}
