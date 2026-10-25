import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gm_campo/main.dart' as app;
import 'package:gm_campo/features/visits/presentation/sketch.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Motorola: demo, measures, quartz, sketch and proposal',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      final demo = find.text('Explorar demo de trabajador');
      await tester.ensureVisible(demo);
      await tester.tap(demo);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Mis visitas'), findsOneWidget);
      final example = find.text('Cliente de demostración');
      await tester.ensureVisible(example);
      await tester.tap(example);
      await tester.pumpAndSettle();
      expect(find.text('Visita técnica'), findsOneWidget);
      final form = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Largo (m)'),
        400,
        scrollable: form,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Generar bosquejo y proforma'),
        500,
        scrollable: form,
      );
      await tester.tap(find.text('Generar bosquejo y proforma'));
      await tester.pumpAndSettle();
      expect(find.text('Bosquejo de mediciones'), findsOneWidget);
      expect(find.byType(Sketch), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Compartir proforma PDF'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Por evaluar'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
