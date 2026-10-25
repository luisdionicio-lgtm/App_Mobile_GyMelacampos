import 'dart:io';
import 'package:flutter/services.dart';

/// Adds only this installation's public local CA. Hostname, expiry and chain
/// validation remain enabled; no badCertificateCallback or TLS bypass is used.
Future<void> configureLocalTls() async {
  final certificate = await rootBundle.load('assets/lan-root-ca.pem');
  SecurityContext.defaultContext.setTrustedCertificatesBytes(
    certificate.buffer.asUint8List(
      certificate.offsetInBytes,
      certificate.lengthInBytes,
    ),
  );
}
