/// Laporan Perkembangan mingguan (lihat backend reportService.js).
class ParentReport {
  final String childName;
  final String? avatarUrl;
  final String weekFrom; // YYYY-MM-DD (Senin)
  final String weekTo; // YYYY-MM-DD (Minggu)
  final int weekOffset;
  final ReportSummary summary;
  final List<ReportActivity> recent;
  final bool detailed; // false = akun gratis (grafik, huruf, saran khusus Premium)
  final List<ReportDay> days;
  final List<LetterMastery> letters;
  final List<String> suggestions;

  const ParentReport({
    required this.childName,
    this.avatarUrl,
    required this.weekFrom,
    required this.weekTo,
    required this.weekOffset,
    required this.summary,
    required this.recent,
    required this.detailed,
    this.days = const [],
    this.letters = const [],
    this.suggestions = const [],
  });

  factory ParentReport.fromJson(Map<String, dynamic> j) {
    final child = j['child'] as Map<String, dynamic>;
    final week = j['week'] as Map<String, dynamic>;
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((j[key] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
    return ParentReport(
      childName: child['name'] as String,
      avatarUrl: child['avatarUrl'] as String?,
      weekFrom: week['from'] as String,
      weekTo: week['to'] as String,
      weekOffset: (week['offset'] as int?) ?? 0,
      summary: ReportSummary.fromJson(j['summary'] as Map<String, dynamic>),
      recent: list('recent', ReportActivity.fromJson),
      detailed: j['detailed'] == true,
      days: list('days', ReportDay.fromJson),
      letters: list('letters', LetterMastery.fromJson),
      suggestions: ((j['suggestions'] as List<dynamic>?) ?? const []).map((e) => '$e').toList(),
    );
  }
}

class ReportSummary {
  final int minutes, prevMinutes, activeDays, streak, lessonsCompleted;
  final double avgStars;
  final int storiesRead, storiesOpened, answers, accuracy;

  const ReportSummary({
    required this.minutes,
    required this.prevMinutes,
    required this.activeDays,
    required this.streak,
    required this.lessonsCompleted,
    required this.avgStars,
    required this.storiesRead,
    required this.storiesOpened,
    required this.answers,
    required this.accuracy,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return ReportSummary(
      minutes: n('minutes'),
      prevMinutes: n('prevMinutes'),
      activeDays: n('activeDays'),
      streak: n('streak'),
      lessonsCompleted: n('lessonsCompleted'),
      avgStars: (j['avgStars'] as num?)?.toDouble() ?? 0,
      storiesRead: n('storiesRead'),
      storiesOpened: n('storiesOpened'),
      answers: n('answers'),
      accuracy: n('accuracy'),
    );
  }
}

class ReportDay {
  final String date, label;
  final int minutes;
  const ReportDay(this.date, this.label, this.minutes);
  factory ReportDay.fromJson(Map<String, dynamic> j) =>
      ReportDay(j['date'] as String, j['label'] as String, (j['minutes'] as num?)?.toInt() ?? 0);
}

enum MasteryStatus { mastered, learning, practice }

class LetterMastery {
  final String letter;
  final int total, accuracy;
  final MasteryStatus status;
  final String? confusedWith;
  const LetterMastery(this.letter, this.total, this.accuracy, this.status, this.confusedWith);
  factory LetterMastery.fromJson(Map<String, dynamic> j) => LetterMastery(
        j['letter'] as String,
        (j['total'] as num?)?.toInt() ?? 0,
        (j['accuracy'] as num?)?.toInt() ?? 0,
        MasteryStatus.values.firstWhere((s) => s.name == j['status'],
            orElse: () => MasteryStatus.learning),
        j['confusedWith'] as String?,
      );
}

class ReportActivity {
  final String icon, text;
  final DateTime? at;
  const ReportActivity(this.icon, this.text, this.at);
  factory ReportActivity.fromJson(Map<String, dynamic> j) => ReportActivity(
        (j['icon'] as String?) ?? '•',
        (j['text'] as String?) ?? '',
        DateTime.tryParse((j['at'] as String?) ?? '')?.toLocal(),
      );
}
