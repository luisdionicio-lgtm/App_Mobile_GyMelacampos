import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/core/theme.dart';
import 'package:gm_campo/features/visits/data/visit_repository.dart';
import 'package:gm_campo/features/visits/domain/visit.dart';
import 'package:gm_campo/features/visits/presentation/visit_editor.dart';

class SavingApi extends Api {
  Map<String, dynamic>? saved;
  @override
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Object? data,
  }) async {
    if (path == '/mobile/visits' && method == 'POST') {
      saved = Map<String, dynamic>.from(data as Map);
      return {
        ...saved!,
        'status': 'En revisión',
        'preview': {'code': 'SOL-TEST', 'preliminary': null},
      };
    }
    throw Exception('Ruta inesperada');
  }
}

void main() {
  testWidgets(
    'Guardar en admin sends valid pieces and quotation to the shared backend',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final api = SavingApi();
      final session = Session(api)
        ..user = {
          'email': 'worker@test.invalid',
          'role': 'medicion',
          'name': 'Operador',
        };
      final repo = VisitRepository(session);
      final material = {
        'id': 'material-1',
        'name': 'Cuarzo',
        'cat': 'Cuarzo',
        'img': '/sample.png',
        'pricePerM2': 0,
      };
      repo.materials = [material];
      final visit = Visit(
        client: 'Cliente de prueba',
        phone: '999111222',
        location: 'Lima',
        materialId: 'material-1',
        material: material,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: gmTheme(),
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) => VisitEditor(repo, existing: visit),
                  ),
                ),
                child: const Text('Abrir visita'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir visita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar en admin'));
      await tester.pumpAndSettle();
      expect(api.saved?['client'], 'Cliente de prueba');
      expect(api.saved?['materialId'], 'material-1');
      expect((api.saved?['pieces'] as List).first['length'], 1.2);
      expect((api.saved?['pieces'] as List).first['width'], .55);
      expect(repo.visits.single.synced, true);
      expect(repo.visits.single.status, 'En revisión');
      repo.dispose();
    },
  );
}
