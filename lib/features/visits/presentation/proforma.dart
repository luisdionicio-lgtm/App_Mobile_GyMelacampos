import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/material_texture.dart';
import '../domain/visit.dart';

bool canGenerateProposal(String role) =>
    ['admin', 'medicion', 'cotizacion'].contains(role);

const navy = PdfColor.fromInt(0xff092744);
const ink = PdfColor.fromInt(0xff0c1d35);
const red = PdfColor.fromInt(0xffb7131b);
const pale = PdfColor.fromInt(0xffeef2f5);
const grid = PdfColor.fromInt(0xffc9d0d7);

Future<Uint8List> buildProforma(
  Visit visit, {
  bool demo = false,
  Uint8List? textureBytes,
}) async {
  final font = pw.Font.ttf(await rootBundle.load('assets/DMSans.ttf'));
  final boldFont = pw.Font.ttf(await rootBundle.load('assets/DMSans-Bold.ttf'));
  final header = pw.MemoryImage(
    (await rootBundle.load('assets/quote-header.png')).buffer.asUint8List(),
  );
  final footer = pw.MemoryImage(
    (await rootBundle.load('assets/quote-footer.png')).buffer.asUint8List(),
  );
  final texture = textureBytes == null ? null : pw.MemoryImage(textureBytes);
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: boldFont),
  );
  final quoteSets = <List<Piece>>[];
  final sketchSets = <List<Piece>>[];
  for (var i = 0; i < visit.pieces.length; i += 4) {
    quoteSets.add(visit.pieces.skip(i).take(4).toList());
  }
  for (var i = 0; i < visit.pieces.length; i += 2) {
    sketchSets.add(visit.pieces.skip(i).take(2).toList());
  }
  final count = quoteSets.length + sketchSets.length;
  var page = 0;
  for (var i = 0; i < quoteSets.length; i++) {
    final l = _Layout(font, boldFont, header, footer, ++page, count);
    l.quotation(visit, quoteSets[i], i * 4, demo);
    doc.addPage(l.page());
  }
  for (var i = 0; i < sketchSets.length; i++) {
    final l = _Layout(font, boldFont, header, footer, ++page, count);
    l.sketch(visit, sketchSets[i], i * 2, texture, demo);
    doc.addPage(l.page());
  }
  return doc.save();
}

Future<void> shareProforma(
  Visit visit, {
  required String role,
  required String serverBase,
  bool demo = false,
}) async {
  if (!canGenerateProposal(role)) {
    throw StateError('Este rol no puede generar documentos.');
  }
  final texture = await loadMaterialTexture(visit, serverBase);
  final bytes = await buildProforma(visit, demo: demo, textureBytes: texture);
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'Propuesta-GM-${visit.id.substring(0, 8)}.pdf',
  );
}

class _Layout {
  final pw.Font font, boldFont;
  final pw.MemoryImage header, footer;
  final int number, count;
  final List<pw.Widget> items = [];
  _Layout(
    this.font,
    this.boldFont,
    this.header,
    this.footer,
    this.number,
    this.count,
  ) {
    put(0, 0, 595.28, 157, pw.Image(header, fit: pw.BoxFit.fill));
    put(0, 790, 595.28, 52, pw.Image(footer, fit: pw.BoxFit.fill));
    label(
      380,
      808,
      180,
      14,
      'G&M Melacampos · Propuesta referencial · $number/$count',
      7,
      align: pw.TextAlign.right,
    );
  }
  void put(double x, double y, double w, double h, pw.Widget child) =>
      items.add(
        pw.Positioned(
          left: x,
          top: y,
          child: pw.SizedBox(width: w, height: h, child: child),
        ),
      );
  void block(
    double x,
    double y,
    double w,
    double h,
    PdfColor fill, {
    PdfColor? border,
  }) => put(
    x,
    y,
    w,
    h,
    pw.Container(
      decoration: pw.BoxDecoration(
        color: fill,
        border: border == null ? null : pw.Border.all(color: border, width: .5),
      ),
    ),
  );
  void label(
    double x,
    double y,
    double w,
    double h,
    String s,
    double size, {
    bool bold = false,
    PdfColor color = ink,
    pw.TextAlign align = pw.TextAlign.left,
  }) => put(
    x,
    y,
    w,
    h,
    pw.Text(
      s,
      maxLines: 2,
      textAlign: align,
      style: pw.TextStyle(
        font: bold ? boldFont : font,
        fontSize: size,
        color: color,
        lineSpacing: 1,
      ),
    ),
  );
  void section(double y, String s) {
    block(28, y, 539, 21, navy);
    block(28, y, 8, 21, red);
    label(45, y + 4, 500, 15, s, 10, bold: true, color: PdfColors.white);
  }

  void field(double y, String name, String value) {
    label(48, y, 105, 16, name, 9, bold: true);
    label(160, y, 12, 16, ':', 9);
    label(186, y, 362, 20, value, 9);
    block(48, y + 22, 500, .5, grid);
  }

  void contact(Visit visit) {
    final company = visit.preview?['company'];
    final details = company is Map ? company : const {};
    for (final (y, glyph) in [(746.0, 'T'), (761.0, '@'), (776.0, 'L')]) {
      block(40, y, 13, 12, navy);
      label(
        40,
        y + 2,
        13,
        10,
        glyph,
        7.5,
        bold: true,
        color: PdfColors.white,
        align: pw.TextAlign.center,
      );
    }
    label(
      61,
      746,
      200,
      14,
      details['phone']?.toString() ?? '+51 956 732 004',
      9,
    );
    label(
      61,
      761,
      240,
      14,
      details['email']?.toString() ?? 'contacto@gmmelacampos.com',
      9,
    );
    label(61, 776, 180, 12, 'Lima, Perú', 9);
    block(307, 746, .7, 41, grid);
    block(402, 765, 165, .8, navy);
    label(
      412,
      770,
      150,
      12,
      'Asesor Comercial',
      8.5,
      bold: true,
      align: pw.TextAlign.center,
    );
    label(
      412,
      782,
      150,
      10,
      details['name']?.toString() ?? 'G&M Melacampos',
      8,
      align: pw.TextAlign.center,
    );
  }

  String code(Visit v, bool demo) =>
      demo ? 'DEMO' : (v.preview?['code']?.toString() ?? 'BORRADOR');
  String date(Visit visit) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final now =
        DateTime.tryParse(
          visit.preview?['issuedAt']?.toString() ?? '',
        )?.toLocal() ??
        DateTime.now();
    return '${now.day} de ${months[now.month - 1]} de ${now.year}';
  }

  void quotation(Visit v, List<Piece> pieces, int offset, bool demo) {
    label(30, 173, 330, 45, 'COTIZACIÓN', 35, bold: true, color: navy);
    label(
      32,
      214,
      320,
      18,
      demo ? 'PROFORMA DEMO · SIN VALIDEZ COMERCIAL' : 'PROFORMA PRELIMINAR',
      10,
      color: navy,
    );
    block(31, 237, 85, 2, red);
    block(116, 237, 218, 2, grid);
    block(364, 171, 203, 75, pale);
    label(376, 180, 30, 19, 'N°', 13, bold: true);
    label(408, 180, 152, 21, code(v, demo), 11, bold: true, color: red);
    label(377, 207, 86, 14, 'Fecha de emisión', 7.3);
    label(463, 207, 98, 14, date(v), 7.2);
    label(377, 226, 100, 14, 'Validez', 8);
    label(463, 226, 98, 14, '30 días', 8);
    section(252, 'DATOS DEL CLIENTE');
    block(28, 273, 539, 84, pale);
    field(284, 'Cliente', v.client);
    field(309, 'Teléfono', v.phone);
    field(334, 'Ubicación', v.location);
    section(368, 'DETALLES DEL PROYECTO');
    block(28, 389, 539, 82, pale);
    field(400, 'Proyecto', v.project);
    field(425, 'Material', v.material?['name']?.toString() ?? 'Por confirmar');
    field(450, 'Referencia', code(v, demo));
    section(483, 'DETALLE DE LA COTIZACIÓN');
    final widths = [38.0, 114.0, 58.0, 58.0, 65.0, 46.0, 64.0, 96.0];
    final heads = [
      'Ítem',
      'Descripción',
      'Largo (m)',
      'Ancho (m)',
      'Espesor (cm)',
      'Cant.',
      'Área (m²)',
      'Importe',
    ];
    double x = 28;
    for (var c = 0; c < widths.length; c++) {
      block(x, 510, widths[c], 22, pale, border: grid);
      label(
        x + 2,
        516,
        widths[c] - 4,
        14,
        heads[c],
        7.2,
        bold: true,
        align: c == 1 ? pw.TextAlign.left : pw.TextAlign.center,
      );
      x += widths[c];
    }
    final rowHeight = math.max(24.0, 48.0 - pieces.length * 6);
    for (var r = 0; r < pieces.length; r++) {
      final p = pieces[r];
      final cells = [
        '${offset + r + 1}',
        p.label,
        p.length.toStringAsFixed(2),
        p.width.toStringAsFixed(2),
        p.thickness.toStringAsFixed(1),
        '${p.quantity}',
        p.area.toStringAsFixed(3),
        '-',
      ];
      x = 28;
      for (var c = 0; c < widths.length; c++) {
        block(
          x,
          532 + rowHeight * r,
          widths[c],
          rowHeight,
          PdfColors.white,
          border: grid,
        );
        label(
          x + 2,
          532 + rowHeight * r + (rowHeight - 14) / 2,
          widths[c] - 4,
          14,
          cells[c],
          8,
          align: c == 1 ? pw.TextAlign.left : pw.TextAlign.center,
        );
        x += widths[c];
      }
    }
    final areaY = 532 + rowHeight * pieces.length + 8;
    final totalY = areaY + 31;
    block(28, areaY, 539, 23, pale);
    label(
      42,
      areaY + 7,
      230,
      15,
      'Área neta: ${v.area.toStringAsFixed(3)} m²',
      10,
      bold: true,
    );
    label(
      286,
      areaY + 7,
      260,
      15,
      'Longitud total: ${v.linear.toStringAsFixed(2)} ML',
      10,
      bold: true,
    );
    final preliminary = v.preview?['preliminary'];
    final amount = preliminary is Map ? preliminary['amount'] : null;
    final amountText = amount is num
        ? 'S/ ${amount.toStringAsFixed(2)}'
        : 'POR EVALUAR';
    block(28, totalY, 335, 53, pale);
    block(363, totalY, 204, 53, red);
    label(
      44,
      totalY + 11,
      300,
      19,
      amount is num ? 'IMPORTE ESTIMADO' : 'IMPORTE: POR EVALUAR',
      12,
      bold: true,
    );
    label(
      44,
      totalY + 33,
      300,
      13,
      amount is num
          ? 'Sujeto a validación administrativa'
          : 'Material sin tarifa configurada',
      8.3,
    );
    label(
      371,
      totalY + 11,
      188,
      13,
      'TOTAL ESTIMADO',
      9,
      bold: true,
      color: PdfColors.white,
      align: pw.TextAlign.center,
    );
    label(
      368,
      totalY + 29,
      194,
      23,
      amountText,
      amount is num ? 18 : 16,
      bold: true,
      color: PdfColors.white,
      align: pw.TextAlign.center,
    );
    contact(v);
  }

  void sketch(
    Visit v,
    List<Piece> pieces,
    int offset,
    pw.MemoryImage? texture,
    bool demo,
  ) {
    label(28, 176, 535, 40, 'BOSQUEJO DE PIEZAS', 29, bold: true, color: navy);
    label(
      30,
      215,
      520,
      18,
      demo ? 'VISTA SUPERIOR · DEMO' : 'VISTA SUPERIOR',
      10,
      color: navy,
    );
    block(30, 237, 61, 2, red);
    block(91, 237, 247, 2, grid);
    block(363, 170, 204, 85, pale);
    block(363, 170, 204, 19, navy);
    block(363, 170, 7, 19, red);
    label(
      375,
      174,
      180,
      13,
      'DATOS DEL CLIENTE',
      9,
      bold: true,
      color: PdfColors.white,
    );
    final clientRows = [
      ('Cliente', v.client),
      ('Teléfono', v.phone),
      ('Ubicación', v.location),
      ('Proyecto', v.project),
      ('Material', v.material?['name']?.toString() ?? 'Por confirmar'),
    ];
    for (var i = 0; i < clientRows.length; i++) {
      final row = clientRows[i];
      final rowY = 194.0 + 12 * i;
      label(373, rowY, 51, 11, row.$1, 7.2, bold: true);
      label(425, rowY, 135, 11, row.$2, row.$2.length > 27 ? 6.5 : 7.5);
    }
    for (var i = 0; i < pieces.length; i++) {
      final p = pieces[i], top = 266.0 + 190 * i;
      block(30, top, 25, 25, red);
      label(
        30,
        top + 4,
        25,
        19,
        '${offset + i + 1}',
        15,
        bold: true,
        color: PdfColors.white,
        align: pw.TextAlign.center,
      );
      label(65, top + 4, 490, 20, p.label, 13, bold: true);
      final heads = [
        'Largo (m)',
        'Ancho (m)',
        'Espesor (cm)',
        'Cantidad',
        'Área (m²)',
      ];
      final vals = [
        p.length.toStringAsFixed(2),
        p.width.toStringAsFixed(2),
        p.thickness.toStringAsFixed(1),
        '${p.quantity}',
        p.area.toStringAsFixed(3),
      ];
      for (var c = 0; c < 5; c++) {
        final x = 42.0 + c * 105;
        block(x, top + 28, 105, 20, pale, border: grid);
        block(x, top + 48, 105, 21, PdfColors.white, border: grid);
        label(
          x + 2,
          top + 33,
          101,
          12,
          heads[c],
          7.6,
          align: pw.TextAlign.center,
        );
        label(
          x + 2,
          top + 53,
          101,
          13,
          vals[c],
          8.5,
          align: pw.TextAlign.center,
        );
      }
      final ratio = p.length / p.width;
      final w = math.min(285.0, 80.0 * ratio), h = w / ratio;
      final x = 190.0 + (285 - w) / 2, y = top + 97 + (80 - h) / 2;
      if (texture == null) {
        block(x, y, w, h, pale, border: ink);
        label(
          x + 5,
          y + h / 2 - 7,
          w - 10,
          20,
          'Textura del catálogo no disponible',
          7.5,
          align: pw.TextAlign.center,
        );
      } else {
        put(x, y, w, h, pw.Image(texture, fit: pw.BoxFit.cover));
        put(
          x,
          y,
          w,
          h,
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: ink, width: 1.2),
            ),
          ),
        );
      }
      block(x, y - 7, w, .7, ink);
      block(x, y - 10, .7, 6, ink);
      block(x + w, y - 10, .7, 6, ink);
      label(
        x,
        y - 22,
        w,
        13,
        '${p.length.toStringAsFixed(2)} m',
        8,
        align: pw.TextAlign.center,
      );
      block(x - 13, y, .7, h, ink);
      block(x - 16, y, 6, .7, ink);
      block(x - 16, y + h, 6, .7, ink);
      label(
        x - 56,
        y + h / 2 - 6,
        39,
        13,
        '${p.width.toStringAsFixed(2)} m',
        8,
        align: pw.TextAlign.right,
      );
      if (i == 0 && pieces.length > 1) block(30, top + 183, 537, .7, grid);
    }
    block(28, 644, 539, 45, pale);
    label(52, 653, 175, 13, 'ÁREA NETA', 9, bold: true, color: navy);
    label(52, 668, 190, 21, '${v.area.toStringAsFixed(3)} m²', 15, bold: true);
    block(294, 650, .7, 34, grid);
    label(328, 653, 220, 13, 'LONGITUD TOTAL', 9, bold: true, color: navy);
    label(
      328,
      668,
      210,
      21,
      '${v.linear.toStringAsFixed(2)} ML',
      15,
      bold: true,
    );
    section(696, 'OBSERVACIONES');
    block(28, 717, 539, 25, pale);
    label(
      45,
      723,
      510,
      17,
      v.notes.isEmpty ? 'Sin observaciones.' : v.notes,
      8.5,
    );
    contact(v);
  }

  pw.Page page() => pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (_) => pw.Stack(children: items),
  );
}
