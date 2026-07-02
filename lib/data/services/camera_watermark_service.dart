import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../core/utils/date_formatter.dart';
import '../models/gps_location_model.dart';

class CameraWatermarkService {
  Future<File> applyWatermark({
    required File originalPhoto,
    required GpsLocationModel location,
    String companyName = 'PT RKM Indonesia',
  }) async {
    final bytes = await originalPhoto.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('File foto tidak dapat diproses.');
    }

    final canvas = img.copyResize(decoded, width: decoded.width);
    final font = img.arial24;

    final lines = <String>[
      companyName,
      DateFormatter.fullDateTime(location.capturedAt),
      location.address,
      location.coordinateText,
    ];

    _drawWatermarkBox(canvas, lines, font);

    final outputBytes = img.encodeJpg(canvas, quality: 85);
    return _saveToFile(outputBytes);
  }

  void _drawWatermarkBox(img.Image canvas, List<String> lines, img.BitmapFont font) {
    const padding = 14;
    const lineHeight = 28;
    final boxHeight = (lines.length * lineHeight) + (padding * 2);
    final boxTop = canvas.height - boxHeight;

    img.fillRect(
      canvas,
      x1: 0,
      y1: boxTop,
      x2: canvas.width,
      y2: canvas.height,
      color: img.ColorRgba8(0, 0, 0, 140),
    );

    var y = boxTop + padding;
    for (final line in lines) {
      img.drawString(
        canvas,
        line,
        font: font,
        x: padding,
        y: y,
        color: img.ColorRgb8(255, 255, 255),
      );
      y += lineHeight;
    }
  }

  Future<File> _saveToFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final fileName = 'rkm_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }
}
