import 'dart:math';
import '../../models/lesson.dart';

/// (Dinamai LessonStepType karena `StepType` sudah dipakai Stepper bawaan Flutter.)
enum LessonStepType { intro, find, listenPick, traceUpper, traceLower, read }

class LessonStep {
  final LessonStepType type;
  final String letter;

  /// Kumpulan huruf untuk pengecoh (mis. semua vokal di unit vokal).
  final List<String> pool;

  const LessonStep(this.type, this.letter, this.pool);
}

/// Susun langkah belajar dari data lesson:
///  - letter    : kenalan -> cari huruf -> (dengar & pilih) -> tulis besar -> tulis kecil -> baca
///  - review    : cari huruf untuk tiap huruf
///  - quiz      : dengar & pilih tiap huruf (jika "Listening Exercise" mati -> cari huruf)
///  - challenge : baca tiap huruf
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
  }
}
