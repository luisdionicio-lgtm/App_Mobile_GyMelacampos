import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/main.dart';
import 'package:gm_campo/features/auth/login.dart';
import 'package:gm_campo/features/visits/domain/visit.dart';
import 'package:gm_campo/features/visits/presentation/proforma.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('rectangular pieces retain units, quantity and precision', () {
    final v = Visit(
      pieces: [
        Piece(length: 1.2, width: .55, quantity: 2),
        Piece(length: .8, width: .1),
      ],
    );
    expect(v.area, closeTo(1.4, 1e-9));
    expect(v.linear, closeTo(3.2, 1e-9));
    final copy = Visit.fromJson(v.toJson());
    expect(copy.id, v.id);
    expect(copy.pieces.first.quantity, 2);
    expect(copy.area, v.area);
  });
  testWidgets('login exposes controlled access and isolated demo', (
    tester,
  ) async {
    await tester.pumpWidget(GmApp(Session(Api())));
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Explorar demo de trabajador'), findsOneWidget);
    expect(find.textContaining('No hay registro público'), findsOneWidget);
  });
  testWidgets('login fits an iPhone screen and keeps connection accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(top: 47, bottom: 34)),
          child: child!,
        ),
        home: LoginPage(Session(Api())),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Configurar conexión'));
    expect(find.text('Configurar conexión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('proforma builds a readable multi-piece PDF without a price', () async {
    final v = Visit(
      client: 'Cliente demo',
      phone: '999111222',
      location: 'Lima',
      material: {'name': 'Cuarzo'},
      pieces: List.generate(8, (i) => Piece(label: 'Pieza $i')),
    );
    final bytes = await buildProforma(v, demo: true);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(5000));
  });
  test('proposal export is available to field workers', () {
    expect(canGenerateProposal('cotizacion'), isTrue);
    expect(canGenerateProposal('medicion'), isTrue);
    expect(canGenerateProposal('admin'), isTrue);
    expect(canGenerateProposal('instalacion'), isFalse);
  });
}
