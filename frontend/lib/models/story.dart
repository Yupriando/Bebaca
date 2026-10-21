/// Progres Baca Bersama satu dongeng.
class StoryProgress {
  final int lastPage; // mulai 0
  final bool completed;
  final int stars;

  const StoryProgress({this.lastPage = 0, this.completed = false, this.stars = 0});

  static StoryProgress? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    return StoryProgress(
      lastPage: (j['lastPage'] as int?) ?? 0,
      completed: j['completed'] == true,
      stars: (j['stars'] as int?) ?? 0,
    );
  }
}

/// Satu soal kuis di akhir dongeng.
class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer; // index jawaban benar

  const QuizQuestion({required this.question, required this.options, required this.answer});

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        question: j['question'] as String,
        options: (j['options'] as List<dynamic>).map((e) => e.toString()).toList(),
        answer: (j['answer'] as int?) ?? 0,
      );
}

class Story {
  final String id;
  final String title;
  final String? coverUrl; // URL (http...) atau path asset. null = placeholder
  final bool isPremium;
  final bool locked; // premium & akun belum berlangganan
  final StoryProgress? progress;
  const Story({
    required this.id,
    required this.title,
    this.coverUrl,
    this.isPremium = false,
    this.locked = false,
    this.progress,
  });

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'] as String,
        title: j['title'] as String,
        coverUrl: j['coverUrl'] as String?,
        isPremium: j['isPremium'] == true,
        locked: j['locked'] == true,
        progress: StoryProgress.fromJson(j['progress']),
      );
}

class StoryCategory {
  final String name;
  final List<Story> stories;
  const StoryCategory({required this.name, required this.stories});

  factory StoryCategory.fromJson(Map<String, dynamic> j) => StoryCategory(
        name: j['name'] as String,
        stories: (j['stories'] as List<dynamic>)
            .map((e) => Story.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Detail dongeng: isi cerita, video (opsional), pesan moral, kuis, progres.
class StoryDetail {
  final String id;
  final String title;
  final String? coverUrl;
  final String? videoUrl;
  final String? content;
  final String? moral;
  final List<QuizQuestion> quiz;
  final List<String> pageImages; // gambar per halaman (opsional)
  final StoryProgress? progress;

  const StoryDetail({
    required this.id,
    required this.title,
    this.coverUrl,
    this.videoUrl,
    this.content,
    this.moral,
    this.quiz = const [],
    this.pageImages = const [],
    this.progress,
  });

  factory StoryDetail.fromJson(Map<String, dynamic> j) => StoryDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        coverUrl: j['coverUrl'] as String?,
        videoUrl: j['videoUrl'] as String?,
        content: j['content'] as String?,
        moral: j['moral'] as String?,
        quiz: ((j['quiz'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(QuizQuestion.fromJson)
            .toList(),
        pageImages: ((j['pageImages'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        progress: StoryProgress.fromJson(j['progress']),
      );
}
