enum LessonStatus { locked, unlocked, completed }

/// letter = belajar 1 huruf | review = latihan | quiz = kuis | challenge = tantangan baca
enum LessonKind { letter, review, quiz, challenge }

class Lesson {
  final String id;
  final String title;
  final LessonKind kind;
  final List<String> letters;
  final LessonStatus status;
  final int stars; // bintang terbaik (0 = belum selesai)

  const Lesson({
    required this.id,
    this.title = '',
    this.kind = LessonKind.letter,
    this.letters = const [],
    required this.status,
    this.stars = 0,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        kind: LessonKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => LessonKind.letter,
        ),
        letters: ((j['letters'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        status: LessonStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => LessonStatus.locked,
        ),
        stars: (j['stars'] as int?) ?? 0,
      );
}

class LessonSection {
  final int unit;
  final int section;
  final String title;
  final String? guide;
  final bool isPremium;
  final bool premiumLocked; // premium & akun belum berlangganan
  final List<Lesson> lessons;

  const LessonSection({
    required this.unit,
    required this.section,
    required this.title,
    this.guide,
    this.isPremium = false,
    this.premiumLocked = false,
    required this.lessons,
  });

  factory LessonSection.fromJson(Map<String, dynamic> j) => LessonSection(
        unit: j['unit'] as int,
        section: j['section'] as int,
        title: j['title'] as String,
        guide: j['guide'] as String?,
        isPremium: j['isPremium'] == true,
        premiumLocked: j['premiumLocked'] == true,
        lessons: (j['lessons'] as List<dynamic>)
            .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
