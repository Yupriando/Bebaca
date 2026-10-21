import 'dart:convert';

/// Pecah isi dongeng menjadi halaman buku bergambar:
/// per paragraf, dan paragraf panjang dipecah per kalimat (maks. ~[maxWords] kata).
/// HARUS sama dengan tool/generate_story_voice.py (supaya rekaman narasi cocok).
List<String> splitPages(String? content, {int maxWords = 24}) {
  final pages = <String>[];
  final paragraphs = (content ?? '')
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((p) => p.isNotEmpty);

  for (final p in paragraphs) {
    final sentences = RegExp(r'[^.!?]+(?:[.!?]+["”]?|$)\s*')
        .allMatches(p)
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty);
    var current = '';
    for (final s in sentences) {
      final next = current.isEmpty ? s : '$current $s';
      if (current.isNotEmpty && wordsOf(next).length > maxWords) {
        pages.add(current);
        current = s;
      } else {
        current = next;
      }
    }
    if (current.isNotEmpty) pages.add(current);
  }
  return pages;
}

/// Kata-kata dalam satu halaman (dipisah spasi, tanda baca ikut katanya).
List<String> wordsOf(String text) =>
    RegExp(r'\S+').allMatches(text).map((m) => m.group(0)!).toList();

/// Nama file narasi untuk teks halaman: "st_" + hash FNV-1a 32-bit (hex).
/// Sama dengan narration_key() di tool/generate_story_voice.py.
String narrationKey(String text) {
  var hash = 0x811c9dc5;
  for (final b in utf8.encode(text)) {
    hash ^= b;
    // hash * 0x01000193 dipecah jadi (hash * 0x193) + (hash << 24), supaya di WEB
    // (angka JavaScript, presisi 53 bit) hasilnya tetap sama persis dengan Android/iOS & Python.
    hash = (hash * 0x193 + ((hash << 24) & 0xffffffff)) & 0xffffffff;
  }
  return 'st_${hash.toRadixString(16).padLeft(8, '0')}';
}

/// Perkiraan lama membaca bersama (anak + narasi pelan ~70 kata/menit).
int readingMinutes(String? content) {
  final words = wordsOf(content ?? '').length;
  return words == 0 ? 0 : (words / 70).ceil();
}
