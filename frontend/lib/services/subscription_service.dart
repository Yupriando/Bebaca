import '../models/subscription.dart';
import 'api_client.dart';

class SubscriptionService {
  final _api = ApiClient.instance;

  Future<SubscriptionStatus> getStatus() async {
    final j = await _api.get('/api/subscription') as Map<String, dynamic>;
    return SubscriptionStatus.fromJson(j);
  }

  /// MODE SIMULASI: jadikan premium tanpa pembayaran.
  Future<SubscriptionStatus> activate(PremiumPlan plan) async {
    final j = await _api.post('/api/subscription/activate',
        body: {'plan': plan.name}) as Map<String, dynamic>;
    return SubscriptionStatus.fromJson(j);
  }

  /// MODE SIMULASI: kembalikan akun ke gratis.
  Future<SubscriptionStatus> deactivate() async {
    final j = await _api.post('/api/subscription/deactivate')
        as Map<String, dynamic>;
    return SubscriptionStatus.fromJson(j);
  }
}
