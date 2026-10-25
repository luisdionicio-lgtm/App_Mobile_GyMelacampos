import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/core/preferences.dart';
import 'package:gm_campo/core/theme.dart';
import 'package:gm_campo/features/visits/data/visit_repository.dart';
import 'package:gm_campo/features/visits/domain/visit.dart';

class OfflineApi extends Api {
  final bool expired;
  OfflineApi({this.expired = false});
  @override
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Object? data,
  }) async {
    if (expired) throw ApiException('Sesión vencida', 401);
    throw Exception('Servidor apagado');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('appearance, accessibility and favorites survive reopening', () async {
    final prefs = AppPreferences();
    await prefs.setMode(ThemeMode.dark);
    await prefs.setAccent(Accent.blue);
    await prefs.setMotion(true);
    await prefs.toggleFavorite('material-1');
    final restored = AppPreferences();
    await restored.load();
    expect(restored.mode, ThemeMode.dark);
    expect(restored.accent, Accent.blue);
    expect(restored.reduceMotion, true);
    expect(restored.favorites, contains('material-1'));
    await restored.toggleFavorite('material-1');
    expect(restored.favorites, isEmpty);
  });
  test('theme text and primary controls retain accessible contrast', () {
    for (final brightness in Brightness.values) {
      for (final accent in Accent.values) {
        final prefs = AppPreferences()..accent = accent;
        final scheme = gmTheme(
          brightness: brightness,
          seed: prefs.seed,
        ).colorScheme;
        double contrast(Color a, Color b) {
          final first = a.computeLuminance(), second = b.computeLuminance();
          return ((first > second ? first : second) + .05) /
              ((first < second ? first : second) + .05);
        }

        expect(
          contrast(scheme.primary, scheme.onPrimary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(scheme.surface, scheme.onSurface),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });
  test(
    'offline startup retains identity; an expired session clears access',
    () async {
      final offline = OfflineApi()..cookie = 'session=fixture';
      final session = Session(offline);
      await Api.storage.write(
        key: session.profileKey,
        value:
            '{"email":"worker@example.invalid","name":"Worker","role":"medicion"}',
      );
      await session.restore();
      expect(session.user?['role'], 'medicion');
      expect(offline.cookie, isNotNull);
      final expired = OfflineApi(expired: true)..cookie = 'session=fixture';
      final invalid = Session(expired);
      await invalid.restore();
      expect(invalid.user, isNull);
      expect(expired.cookie, isNull);
    },
  );
  test(
    'demo drafts persist locally and cannot be sent as real records',
    () async {
      final session = Session(OfflineApi())..startDemo();
      final repo = VisitRepository(session);
      final v = Visit(
        client: 'Solo demo',
        phone: '999000111',
        location: 'Lima',
      );
      await repo.save(v);
      final restored = VisitRepository(session);
      await restored.load();
      expect(restored.visits.any((x) => x.id == v.id), true);
      await expectLater(restored.send(v), throwsException);
      await restored.removeDraft(v);
      expect(restored.visits.any((x) => x.id == v.id), false);
      repo.dispose();
      restored.dispose();
    },
  );
  test(
    'external servers require HTTPS before storing or sending a session',
    () async {
      final api = Api();
      await expectLater(
        api.configure('http://example.invalid'),
        throwsException,
      );
      expect(api.base, 'http://127.0.0.1:8080');
      await api.configure('https://example.invalid');
      expect(api.base, 'https://example.invalid');
    },
  );
}
