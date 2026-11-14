import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gm_campo/core/preferences.dart';
import 'package:gm_campo/core/theme.dart';
import 'package:gm_campo/features/catalog/presentation/catalog_page.dart';
import 'package:gm_campo/features/visits/data/visit_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/core/local_tls.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('selects an available saved HTTPS route on the real phone', (
    tester,
  ) async {
    await configureLocalTls();
    final api = Api()..base = Api.networkBases.first;
    expect(await api.selectNetwork(), isTrue);
    expect(Api.networkBases, contains(api.endpoint));
    expect(api.storageBase, Api.networkBases.first);
    final materials = await api.call('/materials') as List;
    expect(materials, isNotEmpty);
    final repo = VisitRepository(Session(api)..startDemo());
    repo.materials = materials
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
    await tester.pumpWidget(
      PreferencesScope(
        preferences: AppPreferences(),
        child: MaterialApp(
          theme: gmTheme(),
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey('catalog-capture'),
              child: CatalogPage(repo: repo, onUse: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('0 materiales'), findsNothing);
    expect(find.textContaining('No hay materiales'), findsNothing);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('catalog-capture')),
    );
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    binding.reportData = {
      'captures': {
        '09-catalogo-real-android': base64Encode(bytes!.buffer.asUint8List()),
      },
    };
    image.dispose();
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    // Only public health/catalog reads. No business records or session changes.
  });
}
