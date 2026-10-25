import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final source = img.decodePng(File('assets/app-icon.png').readAsBytesSync())!;
  final folder = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  final contents = jsonDecode(
    File('${folder.path}/Contents.json').readAsStringSync(),
  );
  for (final entry in contents['images']) {
    final size =
        (double.parse(entry['size'].split('x')[0]) *
                double.parse(entry['scale'].replaceAll('x', '')))
            .round();
    final icon = img
        .copyResize(
          source,
          width: size,
          height: size,
          interpolation: img.Interpolation.cubic,
        )
        .convert(numChannels: 3);
    File(
      '${folder.path}/${entry['filename']}',
    ).writeAsBytesSync(img.encodePng(icon));
  }
  stdout.writeln('Íconos iOS actualizados desde el monograma de G&M.');
}
