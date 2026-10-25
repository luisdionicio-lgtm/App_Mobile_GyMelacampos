import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gm_campo/main.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/core/preferences.dart';
import 'package:gm_campo/features/visits/domain/visit.dart';
import 'package:gm_campo/features/visits/presentation/sketch.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final captures = <String, String>{};
  Future<void> capture(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    captures[name] = base64Encode(data!.buffer.asUint8List());
    image.dispose();
  }

  testWidgets(
    'Motorola: navigation, themes, favorites, measurements and proposal',
    (tester) async {
      final api = Api();
      await api.init();
      final prefs = AppPreferences();
      await prefs.load();
      final demoKey = 'visits:${api.base}:__demo__';
      final oldDrafts = await Api.storage.read(key: demoKey),
          oldPreferences = await Api.storage.read(key: AppPreferences.key);
      try {
        final materials = await api.call('/materials') as List;
        final quartz = Map<String, dynamic>.from(
          materials.firstWhere((m) => m['cat'] == 'Cuarzo'),
        );
        final fixture = Visit(
          client: 'Cliente de demostración',
          phone: '999000111',
          location: 'Lima · demo',
          materialId: quartz['id'],
          material: quartz,
        );
        await Api.storage.write(
          key: demoKey,
          value: jsonEncode([fixture.toJson()]),
        );
        await prefs.setMode(ThemeMode.light);
        await prefs.setAccent(Accent.gold);
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
        expect(find.text('Buenas ideas.\nMedidas claras.'), findsOneWidget);
        await capture(tester, '01-inicio-claro');
        await tester.tap(find.text('Cuenta'));
        await tester.pumpAndSettle();
        expect(find.text('A tu manera.'), findsOneWidget);
        await tester.tap(find.text('Oscuro'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Azul'));
        await tester.pumpAndSettle();
        expect(prefs.mode, ThemeMode.dark);
        expect(prefs.accent, Accent.blue);
        await capture(tester, '02-cuenta-oscuro-azul');
        await tester.tap(find.text('Materiales'));
        await tester.pumpAndSettle();
        expect(find.text('La piedra indicada.'), findsOneWidget);
        final before = prefs.favorites.toSet();
        final favorite = find.byTooltip('Agregar a favoritos').first;
        await tester.tap(favorite);
        await tester.pumpAndSettle();
        expect(prefs.favorites.length, before.length + 1);
        await capture(tester, '03-catalogo-oscuro');
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Cliente de demostración'));
        await tester.tap(find.text('Cliente de demostración'));
        await tester.pumpAndSettle();
        expect(find.text('Visita técnica'), findsOneWidget);
        await tester.tap(find.text('Generar bosquejo y proforma'));
        await tester.pumpAndSettle();
        expect(find.byType(Sketch), findsOneWidget);
        await capture(tester, '04-bosquejo-oscuro');
        await tester.scrollUntilVisible(
          find.text('Compartir proforma PDF'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Por evaluar'), findsOneWidget);
        await capture(tester, '05-proforma-oscuro');
        binding.reportData = {'captures': captures};
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        if (oldDrafts == null) {
          await Api.storage.delete(key: demoKey);
        } else {
          await Api.storage.write(key: demoKey, value: oldDrafts);
        }
        if (oldPreferences == null) {
          await Api.storage.delete(key: AppPreferences.key);
        } else {
          await Api.storage.write(
            key: AppPreferences.key,
            value: oldPreferences,
          );
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
