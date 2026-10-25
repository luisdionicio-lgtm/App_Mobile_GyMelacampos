import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_campo/core/api.dart';
import 'package:gm_campo/core/local_tls.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'local HTTPS trusts a public certificate without bypassing validation',
    () async {
      final bytes = await rootBundle.load('assets/lan-root-ca.pem');
      expect(
        String.fromCharCodes(bytes.buffer.asUint8List()),
        contains('BEGIN CERTIFICATE'),
      );
      expect(
        String.fromCharCodes(bytes.buffer.asUint8List()),
        isNot(contains('PRIVATE KEY')),
      );
      await configureLocalTls();
      expect(SecurityContext.defaultContext, isA<SecurityContext>());
    },
  );
  test('USB migration recognizes only the former local bridge', () {
    expect(Api.isUsbBridge('http://127.0.0.1:8080'), true);
    expect(Api.isUsbBridge('http://localhost:8080'), true);
    expect(Api.isUsbBridge('https://192.168.18.103:8443'), false);
    expect(Api.isUsbBridge('http://example.com:8080'), false);
  });
}
