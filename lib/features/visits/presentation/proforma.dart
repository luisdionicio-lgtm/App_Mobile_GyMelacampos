import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/visit.dart';

Future<Uint8List> buildProforma(Visit v, {bool demo = false}) async {
  final font = pw.Font.ttf(await rootBundle.load('assets/DMSans.ttf'));
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  final estimate = v.preview?['preliminary'];
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (c) => pw.Text(
        'G&M Melacampos · Propuesta referencial · ${c.pageNumber}/${c.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      build: (c) => [
        pw.Text(
          'G&M Melacampos',
          style: pw.TextStyle(fontSize: 27, color: PdfColor.fromHex('#15357E')),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          demo
              ? 'PROFORMA DEMO · SIN VALIDEZ COMERCIAL'
              : 'PROFORMA PRELIMINAR',
          style: const pw.TextStyle(fontSize: 17),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Cliente: ${v.client}\nTeléfono: ${v.phone}\nUbicación: ${v.location}\nProyecto: ${v.project}\nMaterial: ${v.material?['name'] ?? ''}\nReferencia: ${v.preview?['code'] ?? v.id}\nFecha: ${DateTime.now().toIso8601String().substring(0, 10)}',
        ),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: [
            'Pieza',
            'Largo (m)',
            'Ancho (m)',
            'Espesor (cm)',
            'Cant.',
            'Área (m²)',
          ],
          data: v.pieces
              .map(
                (p) => [
                  p.label,
                  p.length.toStringAsFixed(2),
                  p.width.toStringAsFixed(2),
                  p.thickness.toStringAsFixed(1),
                  '${p.quantity}',
                  p.area.toStringAsFixed(3),
                ],
              )
              .toList(),
          headerStyle: const pw.TextStyle(fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Área neta: ${v.area.toStringAsFixed(3)} m² · Longitud total: ${v.linear.toStringAsFixed(2)} ML',
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          estimate == null
              ? 'Importe: POR EVALUAR — material sin tarifa configurada'
              : 'Estimación: S/ ${(estimate['amount'] as num).toStringAsFixed(2)}\nTarifa: S/ ${estimate['rate']} por ${estimate['unit']} · Cantidad: ${estimate['quantity']} ${estimate['unit']}',
          style: const pw.TextStyle(fontSize: 16),
        ),
        if (estimate?['assemblyIncluded'] == true)
          pw.Text('Armado e instalación incluidos.'),
        pw.SizedBox(height: 16),
        pw.Text(
          'Bosquejo de piezas · vista superior',
          style: const pw.TextStyle(fontSize: 16),
        ),
        for (final p in v.pieces)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${p.label} · ${p.length.toStringAsFixed(2)} × ${p.width.toStringAsFixed(2)} m · ${p.quantity} pieza(s)',
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 250,
                  height: (250 * p.width / p.length).clamp(35, 150).toDouble(),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text('${p.length} m × ${p.width} m'),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Observaciones: ${v.notes.isEmpty ? 'Sin observaciones' : v.notes}',
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Condiciones: medidas ingresadas por el trabajador. Área neta sin optimización de cortes ni merma. Revisar huecos, encuentros y tolerancias antes de fabricar. Importe sujeto a validación administrativa. La imagen IA es conceptual y no sustituye el plano técnico.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    ),
  );
  return doc.save();
}

Future<void> shareProforma(Visit v, {bool demo = false}) async {
  await Printing.sharePdf(
    bytes: await buildProforma(v, demo: demo),
    filename: 'Proforma-GM-${v.id.substring(0, 8)}.pdf',
  );
}
