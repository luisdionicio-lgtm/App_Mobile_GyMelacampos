import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final captures = data?['captures'] as Map<String, dynamic>?;
    if (captures == null) return;
    await Directory('work/modern-screenshots').create(recursive: true);
    for (final entry in captures.entries) {
      await File(
        'work/modern-screenshots/${entry.key}.png',
      ).writeAsBytes(base64Decode(entry.value));
    }
  },
);
