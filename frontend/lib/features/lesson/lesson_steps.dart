import 'dart:math';
import '../../models/lesson.dart';

/// (Dinamai LessonStepType karena `StepType` sudah dipakai Stepper bawaan Flutter.)
enum LessonStepType {
  // huruf
  intro,
  find,
  listenPick,
  traceUpper,
  traceLower,
  read,
  // suku kata
  syllableIntro,
  syllablePick,
  syllableRead,
  // kata
  wordBuild,
  wordRead,
  // kalimat
  sentenceBuild,
  sentenceRead,
}

const vowels = ['A', 'I', 'U', 'E', 'O'];

class LessonStep {
  final LessonStepType type;

  /// Target soal: huruf ("B"), konsonan suku kata ("B"), suku kata ("BA"),
  /// kata ("bola"), atau kalimat ("Ini bola.").
  final String letter;

  /// Potongan target: suku kata sebuah kata (["bo", "la"]) atau kata dalam kalimat.
  final List<String> parts;

  /// Kumpulan huruf/kata di section ini (bahan pengecoh).
  final List<String> pool;

  /// Tanpa latihan mendengar: pilihan suku kata dicocokkan dengan tulisan, bukan suara.
  final bool visual;

  const LessonStep(this.type, this.letter, this.pool, {this.parts = const [], this.visual = false});
}

/// "bo-la" -> ["bo", "la"]
List<String> syllablesOf(String word) =>
    word.toLowerCase().split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

/// "bo-la" -> "bola"
String wordOf(String word) => syllablesOf(word).join();

/// "Ini bola." -> ["Ini", "bola."]
List<String> sentenceWords(String sentence) =>
    sentence.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

/// Susun langkah belajar dari data lesson:
///  - letter    : kenalan -> cari huruf -> (dengar & pilih) -> tulis besar -> tulis kecil -> baca
///  - review    : cari huruf untuk tiap huruf
///  - quiz      : dengar & pilih tiap huruf (jika "Latihan Mendengar" mati -> cari huruf)
///  - challenge : baca tiap huruf
///  - syllable  : kenalan suku kata (b + a = ba) -> pilih & baca suku kata
///                (beberapa konsonan sekaligus = latihan campuran)
///  - word      : tiap kata: susun dari suku kata -> baca kata
///  - sentence  : tiap kalimat: susun kata -> baca kalimat
List<LessonStep> buildSteps(
  Lesson lesson, {
  required bool listening,
  required List<String> pool,
}) {
  final letters = lesson.letters;
  if (letters.isEmpty) return const [];

  final random = Random(lesson.id.hashCode);
  List<String> shuffled() => [...letters]..shuffle(random);

  switch (lesson.kind) {
    case LessonKind.letter:
      final l = letters.first;
      return [
        LessonStep(LessonStepType.intro, l, pool),
        LessonStep(LessonStepType.find, l, pool),
        if (listening) LessonStep(LessonStepType.listenPick, l, pool),
        LessonStep(LessonStepType.traceUpper, l, pool),
        LessonStep(LessonStepType.traceLower, l, pool),
        LessonStep(LessonStepType.read, l, pool),
      ];
    case LessonKind.review:
      return [for (final l in shuffled()) LessonStep(LessonStepType.find, l, pool)];
    case LessonKind.quiz:
      return [
        for (final l in shuffled())
          LessonStep(
            listening ? LessonStepType.listenPick : LessonStepType.find,
            l,
            pool,
          ),
      ];
    case LessonKind.challenge:
      return [for (final l in shuffled()) LessonStep(LessonStepType.read, l, pool)];

    case LessonKind.syllable:
      final consonants = letters.map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList();
      LessonStep pick(String syllable) =>
          LessonStep(LessonStepType.syllablePick, syllable, pool, visual: !listening);
      LessonStep read(String syllable) => LessonStep(LessonStepType.syllableRead, syllable, pool);
      if (consonants.length == 1) {
        final c = consonants.first;
        final v = [...vowels]..shuffle(random);
        return [
          LessonStep(LessonStepType.syllableIntro, c, pool),
          pick('$c${v[0]}'),
          pick('$c${v[1]}'),
          read('$c${v[2]}'),
          pick('$c${v[3]}'),
          read('$c${v[4]}'),
        ];
      }
      // latihan campuran beberapa konsonan
      String any() => '${consonants[random.nextInt(consonants.length)]}${vowels[random.nextInt(vowels.length)]}';
      return [
        for (final c in [...consonants]..shuffle(random)) pick('$c${vowels[random.nextInt(vowels.length)]}'),
        read(any()),
        read(any()),
      ];

    case LessonKind.word:
      return [
        for (final w in letters)
          if (syllablesOf(w).isNotEmpty) ...[
            LessonStep(LessonStepType.wordBuild, wordOf(w), pool, parts: syllablesOf(w)),
            LessonStep(LessonStepType.wordRead, wordOf(w), pool, parts: syllablesOf(w)),
          ],
      ];

    case LessonKind.sentence:
      return [
        for (final s in letters)
          if (sentenceWords(s).isNotEmpty) ...[
            LessonStep(LessonStepType.sentenceBuild, s.trim(), pool, parts: sentenceWords(s)),
            LessonStep(LessonStepType.sentenceRead, s.trim(), pool, parts: sentenceWords(s)),
          ],
      ];
  }
}

/// Pengecoh untuk pilihan suku kata [target] (mis. "BU"):
/// satu dengan konsonan sama tetapi vokal beda ("BA"), satu dengan vokal sama
/// tetapi konsonan beda ("DU") supaya anak benar-benar memperhatikan kedua bunyi.
List<String> syllableDistractors(String target, List<String> pool, int count, Random random) {
  final t = target.toUpperCase();
  final c = t.substring(0, t.length - 1);
  final v = t.substring(t.length - 1);
  final consonants = <String>{
    for (final p in pool)
      if (p.length == 1 && !vowels.contains(p.toUpperCase()) && RegExp(r'^[A-Za-z]$').hasMatch(p)) p.toUpperCase(),
  }..remove(c);
  final fallback = 'BDGKLMNPST'.split('').where((x) => x != c).toList()..shuffle(random);
  final otherC = consonants.isNotEmpty ? (consonants.toList()..shuffle(random)).first : fallback.first;
  final otherV = (vowels.where((x) => x != v).toList()..shuffle(random));

  final result = <String>['$c${otherV[0]}', '$otherC$v'];
  var i = 1;
  while (result.length < count) {
    result.add('$c${otherV[i++ % otherV.length]}');
  }
  return result.toSet().where((x) => x != t).take(count).toList();
}
