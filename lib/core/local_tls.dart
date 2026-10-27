import 'dart:io';
import 'package:flutter/services.dart';

/// Adds only this installation's public local CA. Hostname, expiry and chain
/// validation remain enabled; no badCertificateCallback or TLS bypass is used.
Future<void> configureLocalTls() async {
  for (final asset in [
    'assets/lan-root-ca.pem',
    'assets/lan-root-ca-mac.pem',
  ]) {
    final certificate = await rootBundle.load(asset);
    SecurityContext.defaultContext.setTrustedCertificatesBytes(
      certificate.buffer.asUint8List(
        certificate.offsetInBytes,
        certificate.lengthInBytes,
      ),
    );
  }
}
