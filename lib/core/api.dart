import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, this.status);
  @override
  String toString() => message;
}

class Api {
  static const storage = FlutterSecureStorage();
  static const defaultBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
  String base = defaultBase;
  String? cookie;
  static bool isUsbBridge(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'http' &&
        ['127.0.0.1', 'localhost'].contains(uri.host) &&
        uri.port == 8080;
  }

  Future<void> init() async {
    final saved = await storage.read(key: 'server');
    base = saved ?? defaultBase;
    if (defaultBase.startsWith('https://') &&
        (saved == null || isUsbBridge(saved))) {
      final old = saved ?? 'http://127.0.0.1:8080';
      final records = await storage.readAll();
      for (final entry in records.entries) {
        String? target;
        if (entry.key.startsWith('visits:$old:')) {
          target =
              'visits:$defaultBase${entry.key.substring(('visits:$old').length)}';
        }
        if (entry.key == 'catalog:$old') {
          target = 'catalog:$defaultBase';
        }
        if (target != null && !records.containsKey(target)) {
          await storage.write(key: target, value: entry.value);
        }
      }
      if (saved != defaultBase) {
        await storage.delete(key: 'session');
      }
      base = defaultBase;
      await storage.write(key: 'server', value: base);
    }
    cookie = await storage.read(key: 'session');
  }

  Future<void> configure(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw Exception('Indica una URL http o https válida');
    }
    if (uri.scheme == 'http' &&
        !['localhost', '127.0.0.1', '::1', '10.0.2.2'].contains(uri.host)) {
      throw Exception('Usa HTTPS para conectar fuera del enlace local USB.');
    }
    base = value.trim().replaceAll(RegExp(r'/$'), '');
    cookie = null;
    await storage.delete(key: 'session');
    await storage.write(key: 'server', value: base);
  }

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (cookie != null) 'Cookie': cookie!,
  };
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Object? data,
  }) async {
    final request = http.Request(method, Uri.parse('$base/api$path'))
      ..headers.addAll(headers);
    if (data != null) request.body = jsonEncode(data);
    try {
      final response = await http.Response.fromStream(
        await request.send(),
      ).timeout(Duration(seconds: path.endsWith("/image") ? 195 : 12));
      final body = response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 400) {
        throw ApiException(
          body?['error'] ?? 'No se pudo completar la operación',
          response.statusCode,
        );
      }
      if (path == '/auth/login') {
        cookie = response.headers['set-cookie']?.split(';').first;
        await storage.write(key: 'session', value: cookie);
      }
      return body;
    } on TimeoutException {
      throw Exception(
        'El servidor tarda en responder. Comprueba Docker y vuelve a intentar.',
      );
    } on http.ClientException {
      throw Exception(
        'Sin conexión. Comprueba Docker y el enlace USB o la dirección del servidor.',
      );
    }
  }

  Future<void> photo(String id, String file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$base/api/mobile/visits/$id/photo'),
    );
    if (cookie != null) request.headers['Cookie'] = cookie!;
    final content = await File(file).readAsBytes();
    if (content.length > 10 * 1024 * 1024) {
      throw Exception('La foto debe pesar menos de 10 MB');
    }
    final png = content.length > 4 && content[0] == 137 && content[1] == 80;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file,
        filename: png ? 'Visita.png' : 'Visita.jpg',
        contentType: MediaType('image', png ? 'png' : 'jpeg'),
      ),
    );
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 45)),
    );
    if (response.statusCode >= 400) {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  Future<void> logout() async {
    try {
      await call('/auth/logout', method: 'POST');
    } finally {
      cookie = null;
      await storage.delete(key: 'session');
    }
  }
}

class Session extends ChangeNotifier {
  final Api api;
  Session(this.api);
  Map<String, dynamic>? user;
  bool demo = false;
  bool get canEdit =>
      demo || ['admin', 'medicion', 'cotizacion'].contains(user?['role']);
  String get profileKey => 'profile:${api.base}';
  Future<void> restore() async {
    if (api.cookie == null) return;
    final cached = await Api.storage.read(key: profileKey);
    if (cached != null) {
      try {
        user = Map<String, dynamic>.from(jsonDecode(cached));
      } catch (_) {}
    }
    try {
      await verify().timeout(const Duration(seconds: 5));
    } catch (_) {
      /* Keep local drafts and cached identity while Docker is offline. Server still enforces every permission. */
    }
  }

  Future<void> verify() async {
    try {
      user = Map<String, dynamic>.from(await api.call('/mobile/me'));
      await Api.storage.write(key: profileKey, value: jsonEncode(user));
    } on ApiException catch (e) {
      if (e.status == 401) {
        user = null;
        api.cookie = null;
        await Api.storage.delete(key: 'session');
        await Api.storage.delete(key: profileKey);
      } else {
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    user = Map<String, dynamic>.from(
      await api.call(
        '/auth/login',
        method: 'POST',
        data: {'email': email.trim(), 'password': password},
      ),
    );
    demo = false;
    await Api.storage.write(key: profileKey, value: jsonEncode(user));
    notifyListeners();
  }

  void startDemo() {
    demo = true;
    user = {'name': 'Trabajador demo', 'email': 'demo', 'role': 'medicion'};
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (!demo) await api.logout();
    } catch (_) {
      api.cookie = null;
      await Api.storage.delete(key: 'session');
    }
    if (!demo) await Api.storage.delete(key: profileKey);
    demo = false;
    user = null;
    notifyListeners();
  }
}
