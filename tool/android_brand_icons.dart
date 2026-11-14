import 'dart:io';
import 'package:image/image.dart' as img;

/// Android resources only. Keeps the shared source and iOS icons untouched.
void main() {
  final source = img.decodePng(
    File('tool/app-icon-source.png').readAsBytesSync(),
  )!;
  const densities = {
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0,
  };
  for (final entry in densities.entries) {
    final folder = Directory('android/app/src/main/res/mipmap-${entry.key}')
      ..createSync(recursive: true);
    final legacy = (48 * entry.value).round();
    File('${folder.path}/ic_launcher.png').writeAsBytesSync(
      img.encodePng(
        img.copyResize(
          source,
          width: legacy,
          height: legacy,
          interpolation: img.Interpolation.cubic,
        ),
      ),
    );
    final size = (108 * entry.value).round();
    final artworkSize = (86 * entry.value).round();
    final foreground = img.Image(width: size, height: size, numChannels: 4);
    img.compositeImage(
      foreground,
      img.copyResize(
        source,
        width: artworkSize,
        height: artworkSize,
        interpolation: img.Interpolation.cubic,
      ),
      dstX: (size - artworkSize) ~/ 2,
      dstY: (size - artworkSize) ~/ 2,
    );
    File(
      '${folder.path}/ic_launcher_foreground.png',
    ).writeAsBytesSync(img.encodePng(foreground));
  }
  stdout.writeln(
    'Android: iconos clásicos y adaptables generados desde el logo compartido.',
  );
}
