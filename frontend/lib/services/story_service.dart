import '../models/story.dart';
import 'api_client.dart';
import 'remote_voice.dart';

class StoryService {
  final _api = ApiClient.instance;

  Future<List<StoryCategory>> getCategories() async {
    final data = await _api.get('/api/stories') as List<dynamic>;
    return data
        .map((e) => StoryCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoryDetail> getStory(String id) async {
    final data = await _api.get('/api/stories/$id') as Map<String, dynamic>;
    final story = StoryDetail.fromJson(data);
    RemoteVoice.instance.setBase(story.narrationBaseUrl); // rekaman suara AI di Supabase Storage
    return story;
  }

  /// Simpan halaman terakhir Baca Bersama (dan tandai selesai + bintang di akhir).
  Future<StoryProgress?> saveProgress(
    String id, {
    required int page,
    bool? completed,
    int? stars,
  }) async {
    final data = await _api.post('/api/stories/$id/progress', body: {
      'page': page,
      if (completed != null) 'completed': completed,
      if (stars != null) 'stars': stars,
    });
    return StoryProgress.fromJson(data);
  }
}
