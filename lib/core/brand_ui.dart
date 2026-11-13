import 'package:flutter/material.dart';

const gmNavy = Color(0xff06233c);
const gmRed = Color(0xffc80d20);
const gmGold = Color(0xffd3a13d);
const gmCream = Color(0xfff7f5f1);

class GmPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GmPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffe5e7eb)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1206233c),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class GmAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool gold;
  const GmAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: gold ? gmGold : gmRed,
        foregroundColor: gold ? gmNavy : Colors.white,
        minimumSize: const Size.fromHeight(52),
        elevation: 3,
        side: BorderSide(color: gold ? gmNavy : gmGold, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class GmPageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const GmPageTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontFamily: 'Playfair Display',
          fontSize: 29,
          fontWeight: FontWeight.w700,
          color: gmNavy,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 5),
        Text(
          subtitle!,
          style: const TextStyle(color: Color(0xff53606b), fontSize: 14),
        ),
      ],
    ],
  );
}

class GmStatus extends StatelessWidget {
  final String status;
  const GmStatus(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final valid = status == 'Validada' || status == 'Instalado';
    final draft = status == 'Borrador';
    final background = valid
        ? const Color(0xffd9f4e2)
        : draft
        ? const Color(0xffe3ebfb)
        : const Color(0xffffedb6);
    final foreground = valid
        ? const Color(0xff145632)
        : draft
        ? const Color(0xff183e82)
        : const Color(0xff765000);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
