import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gm_campo/main.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/core/local_tls.dart';
import 'package:gm_campo/core/preferences.dart';
import 'package:gm_campo/features/visits/domain/visit.dart';

class OfflineDemoApi extends Api {
  OfflineDemoApi() : super(networkProbe: (_) async => false);
  @override
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Object? data,
  }) async {
    throw Exception('La demo visual usa el catálogo local.');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android e iOS: pantallas de visita y propuesta en demo',
    (tester) async {
      await configureLocalTls();
      final api = OfflineDemoApi();
      await api.init();
      final prefs = AppPreferences();
      await prefs.load();
      final key = 'visits:${api.storageBase}:__demo__';
      final catalogKey = 'catalog:${api.storageBase}';
      final previousDrafts = await Api.storage.read(key: key);
      final previousCatalog = await Api.storage.read(key: catalogKey);
      final previousPrefs = await Api.storage.read(key: AppPreferences.key);
      final captures = <String, String>{};
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('capture')),
        );
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        captures[name] = base64Encode(data!.buffer.asUint8List());
        image.dispose();
      }

      try {
        final material = <String, dynamic>{
          'id': 'demo-cuarzo',
          'name': 'Cuarzo Blanco',
          'cat': 'Cuarzo',
          'img': '/materials/demo-cuarzo.jpg',
          'pricePerM2': 0,
        };
        await Api.storage.write(key: catalogKey, value: jsonEncode([material]));
        final fixture = Visit(
          client: 'Cliente de demostración',
          phone: '999000111',
          location: 'Lima',
          project: 'Cocina',
          materialId: material['id'],
          material: material,
        );
        await Api.storage.write(
          key: key,
          value: jsonEncode([fixture.toJson()]),
        );
        await prefs.setMode(ThemeMode.light);
        final session = Session(api);
        runApp(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: GmApp(session, preferences: prefs),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Explorar demo de trabajador'));
        await tester.tap(find.text('Explorar demo de trabajador'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.textContaining('Hola, TRABAJADOR', findRichText: true), findsOneWidget);
        await capture('01-inicio');

        await tester.tap(find.text('Materiales').last);
        await tester.pumpAndSettle();
        expect(find.text('Nuestro catálogo'), findsOneWidget);
        await capture('02-materiales');

        await tester.tap(find.text('Visitas').last);
        await tester.pumpAndSettle();
        await capture('03-visitas');
        await tester.tap(find.text('Cliente de demostración').first);
        await tester.pumpAndSettle();
        expect(find.text('Datos del cliente'), findsOneWidget);
        await capture('04-cliente');
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Piezas y medidas'), findsWidgets);
        await capture('05-medidas');
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        await capture('06-material-elegido');
        await tester.tap(find.text('Calcular propuesta'));
        await tester.pumpAndSettle();
        expect(find.text('Visualizar con IA'), findsWidgets);
        await capture('07-ia');
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Propuesta completa'), findsWidgets);
        await capture('08-propuesta');
        binding.reportData = {'captures': captures};
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        if (previousDrafts == null) {
          await Api.storage.delete(key: key);
        } else {
          await Api.storage.write(key: key, value: previousDrafts);
        }
        if (previousPrefs == null) {
          await Api.storage.delete(key: AppPreferences.key);
        } else {
          await Api.storage.write(
            key: AppPreferences.key,
            value: previousPrefs,
          );
        }
        if (previousCatalog == null) {
          await Api.storage.delete(key: catalogKey);
        } else {
          await Api.storage.write(key: catalogKey, value: previousCatalog);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
