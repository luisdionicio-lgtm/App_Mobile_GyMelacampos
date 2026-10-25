import 'dart:math';
import 'package:flutter/material.dart';
import '../domain/visit.dart';
import '../../../core/theme.dart';

class Sketch extends StatelessWidget {
  final Visit visit;
  const Sketch(this.visit, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final p in visit.pieces)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p.label} · ${p.quantity} pieza(s) · espesor ${p.thickness} cm',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 210,
                width: double.infinity,
                child: CustomPaint(painter: PiecePainter(p)),
              ),
            ],
          ),
        ),
    ],
  );
}

class PiecePainter extends CustomPainter {
  final Piece p;
  PiecePainter(this.p);
  @override
  void paint(Canvas c, Size size) {
    final scale = min(
      (size.width - 100) / p.length,
      (size.height - 75) / p.width,
    );
    final w = p.length * scale, h = p.width * scale;
    final r = Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
    final fill = Paint()..color = const Color(0xffF3EFE8);
    final stroke = Paint()
      ..color = carbon
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    c.drawRect(r, fill);
    c.drawRect(r, stroke);
    void label(String text, Offset offset) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: carbon,
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, offset - Offset(tp.width / 2, tp.height / 2));
    }

    final dim = Paint()
      ..color = gold
      ..strokeWidth = 1;
    final y = r.bottom + 22;
    c.drawLine(Offset(r.left, y), Offset(r.right, y), dim);
    for (final x in [r.left, r.right]) {
      c.drawLine(Offset(x, y - 5), Offset(x, y + 5), dim);
    }
    label('${p.length.toStringAsFixed(2)} m', Offset(r.center.dx, y + 15));
    final x = r.right + 18;
    c.drawLine(Offset(x, r.top), Offset(x, r.bottom), dim);
    for (final y in [r.top, r.bottom]) {
      c.drawLine(Offset(x - 5, y), Offset(x + 5, y), dim);
    }
    c.save();
    c.translate(x + 16, r.center.dy);
    c.rotate(-pi / 2);
    label('${p.width.toStringAsFixed(2)} m', Offset.zero);
    c.restore();
    label('${p.area.toStringAsFixed(3)} m²', r.center);
  }

  @override
  bool shouldRepaint(PiecePainter oldDelegate) => true;
}
