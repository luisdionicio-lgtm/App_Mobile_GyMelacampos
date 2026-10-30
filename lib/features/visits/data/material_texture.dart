import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../domain/visit.dart';

/// Keeps only the selected catalog image for use in a proforma without Wi-Fi.
Future<Uint8List?> loadMaterialTexture(Visit visit, String serverBase) async {
  final imagePath = visit.material?['img'];
  if (imagePath is! String || !imagePath.startsWith('/materials/')) {
    return null;
  }
  final server = Uri.tryParse(serverBase);
  if (server == null || !['http', 'https'].contains(server.scheme)) return null;
  final uri = server.resolve(imagePath);
  if (uri.host != server.host || uri.port != server.port) return null;

  final safeServer = '${server.host}_${server.port}'.replaceAll(
    RegExp(r'[^a-zA-Z0-9_-]'),
    '_',
  );
  final safeName = '${visit.materialId}_${uri.pathSegments.last}'.replaceAll(
    RegExp(r'[^a-zA-Z0-9_.-]'),
    '_',
  );
  final directory = Directory(
    '${(await getApplicationSupportDirectory()).path}/material-textures/$safeServer',
  );
  final file = File('${directory.path}/$safeName');

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200 &&
        response.bodyBytes.length <= 8 * 1024 * 1024 &&
        _supportedImage(response.bodyBytes)) {
      await directory.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return response.bodyBytes;
    }
  } catch (_) {
    // An earlier copy can still be used when the phone is offline.
  }
  if (!await file.exists()) return null;
  final cached = await file.readAsBytes();
  return _supportedImage(cached) ? cached : null;
}

bool _supportedImage(Uint8List bytes) =>
    bytes.length > 8 &&
    ((bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4e &&
            bytes[3] == 0x47) ||
        (bytes[0] == 0xff && bytes[1] == 0xd8));
