import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/api.dart';
import '../domain/visit.dart';

class VisitRepository extends ChangeNotifier {
  final Session session;
  VisitRepository(this.session);
  List<Visit> visits = [];
  List<Map<String, dynamic>> materials = [];
  String? error;
  String get _key => 'visits:${session.api.base}:${session.user?['email']}';
  Future<void> saveLocal() async {
    if (!session.demo) {
      await Api.storage.write(
        key: _key,
        value: jsonEncode(visits.map((v) => v.toJson()).toList()),
      );
    }
    notifyListeners();
  }

  Future<void> load() async {
    final saved = session.demo ? null : await Api.storage.read(key: _key);
    visits = saved == null
        ? []
        : (jsonDecode(saved) as List).map((v) => Visit.fromJson(v)).toList();
    try {
      materials = (await session.api.call('/materials') as List)
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
      await Api.storage.write(
        key: 'catalog:${session.api.base}',
        value: jsonEncode(materials),
      );
      error = null;
    } catch (e) {
      final cached = await Api.storage.read(key: 'catalog:${session.api.base}');
      materials = cached == null
          ? []
          : (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
      error = e.toString();
    }
    if (session.demo) {
      final quartz = materials.where((m) => m['cat'] == 'Cuarzo').firstOrNull;
      visits = [
        Visit(
          client: 'Cliente de demostración',
          phone: '999000111',
          location: 'Lima · visita de ejemplo',
          materialId: quartz?['id'] ?? '',
          material: quartz,
          notes: 'Ejemplo local. No se envía al administrador.',
        ),
      ];
    } else {
      try {
        final remote = await session.api.call('/mobile/visits') as List;
        for (final m in remote) {
          final v = Visit.fromJson({...m, 'synced': true});
          final i = visits.indexWhere((x) => x.id == v.id);
          if (i < 0) {
            visits.add(v);
          } else if (visits[i].synced) {
            v.photo = visits[i].photo;
            visits[i] = v;
          }
        }
      } catch (e) {
        error = e.toString();
      }
    }
    await saveLocal();
  }

  Future<void> save(Visit v) async {
    final i = visits.indexWhere((x) => x.id == v.id);
    if (i < 0) {
      visits.insert(0, v);
    } else {
      visits[i] = v;
    }
    await saveLocal();
  }

  Future<void> calculate(Visit v) async {
    final result = await session.api.call(
      '/mobile/preview',
      method: 'POST',
      data: v.payload(),
    );
    v.preview = result['preview'];
    v.material = result['material'];
    await save(v);
  }

  Future<void> send(Visit v) async {
    if (session.demo) {
      throw Exception(
        'La demo es local. Inicia sesión con una cuenta creada por el administrador para enviar visitas.',
      );
    }
    final result = await session.api.call(
      '/mobile/visits',
      method: 'POST',
      data: v.payload(),
    );
    v.preview = result['preview'];
    v.status = result['status'];
    v.synced = true;
    await save(v);
  }
}
