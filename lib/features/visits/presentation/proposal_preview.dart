import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/brand_ui.dart';
import '../data/material_texture.dart';
import '../domain/visit.dart';
import 'proforma.dart';

class ProposalPreviewPage extends StatelessWidget {
  final Visit visit;
  final String serverBase;
  final bool demo;
  const ProposalPreviewPage(
    this.visit, {
    super.key,
    required this.serverBase,
    required this.demo,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vista del PDF')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: GmPanel(
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined, color: gmRed),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Un documento con cotización y bosquejos de las piezas',
                    style: TextStyle(
                      color: gmNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: PdfPreview(
            pdfFileName: 'Propuesta-GM-${visit.id.substring(0, 8)}.pdf',
            canChangeOrientation: false,
            canChangePageFormat: false,
            build: (_) async {
              final texture = await loadMaterialTexture(visit, serverBase);
              return buildProforma(visit, demo: demo, textureBytes: texture);
            },
          ),
        ),
      ],
    ),
  );
}
