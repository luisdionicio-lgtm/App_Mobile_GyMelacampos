import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_campo/core/api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('saved LAN address follows the current build without losing session', () async {
    if (!Api.networkBases.contains(Api.defaultBase)) return;
    final previous = Api.networkBases.first;
    FlutterSecureStorage.setMockInitialValues({
      'server': previous,
      'session': 'session=test',
    });
    final api = Api();
    await api.init();
    expect(api.base, Api.defaultBase);
    expect(api.cookie, 'session=test');
    expect(await Api.storage.read(key: 'server'), Api.defaultBase);
  });
  test(
    'alias migration merges once and never resurrects removed drafts',
    () async {
      final home = Api.networkBases.first, hotspot = Api.networkBases.last;
      FlutterSecureStorage.setMockInitialValues({
        'server': hotspot,
        'visits:$hotspot:worker': '[{"id":"a","client":"hotspot"}]',
        'visits:$home:worker': '[{"id":"b","client":"home"}]',
      });
      await Api().init();
      final key = 'visits:$home:worker';
      expect(
        (jsonDecode((await Api.storage.read(key: key))!) as List).length,
        2,
      );
      await Api.storage.write(key: key, value: '[]');
      await Api().init();
      expect(await Api.storage.read(key: key), '[]');
      expect(await Api.storage.read(key: 'visits:$hotspot:worker'), isNotNull);
    },
  );
  test(
    'switches between trusted routes without changing identity or cookie',
    () async {
      var available = Api.networkBases[1];
      final api = Api(networkProbe: (url) async => url == available)
        ..base = Api.networkBases.first
        ..cookie = 'session=test';
      expect(await api.selectNetwork(), isTrue);
      expect(api.endpoint, available);
      expect(api.storageBase, Api.networkBases.first);
      available = Api.networkBases.first;
      expect(await api.selectNetwork(), isTrue);
      expect(api.endpoint, available);
      expect(api.cookie, 'session=test');
    },
  );
  test(
    'custom servers never probe or share credentials with local aliases',
    () async {
      final probed = <String>[];
      final api = Api(
        networkProbe: (url) async {
          probed.add(url);
          return false;
        },
      )..base = 'https://example.invalid';
      expect(await api.selectNetwork(), isFalse);
      expect(probed, ['https://example.invalid']);
      expect(api.storageBase, api.base);
    },
  );
}
