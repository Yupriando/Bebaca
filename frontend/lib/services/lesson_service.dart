import '../models/lesson.dart';
import 'api_client.dart';

class LessonService {
  final _api = ApiClient.instance;

  Future<List<LessonSection>> getSections() async {
    final data = await _api.get('/api/lessons') as List<dynamic>;
    return data
        .map((e) => LessonSection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Simpan lesson selesai + bintang (0-3).
  /// Mengembalikan jumlah hari belajar berturut-turut terbaru (null bila tidak tersedia).
  Future<int?> completeLesson(String lessonId, {int stars = 1}) async {
    final data = await _api.post(
      '/api/lessons/$lessonId/complete',
      body: {'stars': stars},
    ) as Map<String, dynamic>;
    return data['hariBerturut'] as int?;
  }
}
