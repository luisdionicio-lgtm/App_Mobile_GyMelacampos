import 'package:flutter_test/flutter_test.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/main.dart';
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
}
