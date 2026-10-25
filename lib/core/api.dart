import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class Api {
  static const storage = FlutterSecureStorage();
  String base = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
  String? cookie;
  Future<void> init() async {
    base = await storage.read(key: 'server') ?? base;
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
        await request.send().timeout(const Duration(seconds: 195)),
      );
      final body = response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 400) {
        throw Exception(body?['error'] ?? 'No se pudo completar la operación');
      }
      if (path == '/auth/login') {
        cookie = response.headers['set-cookie']?.split(';').first;
        await storage.write(key: 'session', value: cookie);
      }
      return body;
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
  Future<void> restore() async {
    if (api.cookie != null) {
      try {
        user = Map<String, dynamic>.from(await api.call('/mobile/me'));
      } catch (_) {
        api.cookie = null;
        await Api.storage.delete(key: 'session');
      }
    }
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
    notifyListeners();
  }

  void startDemo() {
    demo = true;
    user = {'name': 'Trabajador demo', 'email': 'demo', 'role': 'medicion'};
    notifyListeners();
  }

  Future<void> logout() async {
    if (!demo) await api.logout();
    demo = false;
    user = null;
    notifyListeners();
  }
}
