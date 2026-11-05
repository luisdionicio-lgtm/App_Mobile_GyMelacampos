import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/core/local_tls.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('selects an available saved HTTPS route on the real phone', (
    _,
  ) async {
    await configureLocalTls();
    final api = Api()..base = Api.networkBases.first;
    expect(await api.selectNetwork(), isTrue);
    expect(Api.networkBases.take(2), contains(api.endpoint));
    expect(api.storageBase, Api.networkBases.first);
    final materials = await api.call('/materials') as List;
    expect(materials, isNotEmpty);
    // Only public health/catalog reads. No business records or session changes.
  });
}
