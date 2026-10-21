import '../models/report.dart';
import 'api_client.dart';

class ReportService {
  final _api = ApiClient.instance;

  /// [week]: 0 = minggu ini, 1 = minggu lalu, ...
  Future<ParentReport> getReport({int week = 0}) async {
    final j = await _api.get('/api/report?week=$week') as Map<String, dynamic>;
    return ParentReport.fromJson(j);
  }

  /// Apakah tautan Pantau Langsung sedang aktif.
  Future<bool> monitorActive() async {
    final j = await _api.get('/api/report/monitor-link') as Map<String, dynamic>;
    return j['active'] == true;
  }

  /// Buat tautan Pantau Langsung baru (tautan/QR lama otomatis tidak berlaku). Mengembalikan URL.
  Future<String> createMonitorLink() async {
    final j = await _api.post('/api/report/monitor-link') as Map<String, dynamic>;
    return j['url'] as String;
  }

  Future<void> revokeMonitorLink() => _api.delete('/api/report/monitor-link');
}
