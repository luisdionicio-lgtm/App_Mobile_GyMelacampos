import 'package:flutter/material.dart';
import 'brand_ui.dart';

class GmInnerBackground extends StatelessWidget {
  final Widget child;
  const GmInnerBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/home-white-gold-marble.png', fit: BoxFit.cover),
      ColoredBox(color: Colors.white.withValues(alpha: .28)),
      child,
    ],
  );
}

AppBar gmInnerAppBar({
  required String title,
  Widget? leading,
  List<Widget>? actions,
}) => AppBar(
  title: Text(
    title,
    style: const TextStyle(
      fontFamily: 'Playfair Display',
      fontWeight: FontWeight.w700,
      fontSize: 22,
    ),
  ),
  leading: leading,
  actions: actions,
  flexibleSpace: Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/login-navy-marble.jpg', fit: BoxFit.cover),
      ColoredBox(color: gmNavy.withValues(alpha: .22)),
      const Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [gmRed, gmGold, gmGold]),
            ),
          ),
        ),
      ),
    ],
  ),
);

class GmInnerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GmInnerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .95),
      image: const DecorationImage(
        image: AssetImage('assets/home-white-gold-marble.png'),
        fit: BoxFit.cover,
        opacity: .16,
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: gmGold, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2606233c),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class GmInnerHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? accent;
  final String? subtitle;
  final IconData icon;
  const GmInnerHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.accent,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: gmNavy,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: gmGold, width: 1.3),
            ),
            child: Icon(icon, color: gmGold, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: Color(0xffa47722),
                letterSpacing: 2.2,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: title),
            if (accent != null)
              TextSpan(
                text: ' $accent',
                style: const TextStyle(
                  color: Color(0xffb5832f),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        style: const TextStyle(
          fontFamily: 'Playfair Display',
          color: gmNavy,
          fontWeight: FontWeight.w700,
          fontSize: 29,
          height: 1.15,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 7),
        Text(
          subtitle!,
          style: const TextStyle(
            color: Color(0xff445466),
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ],
    ],
  );
}

InputDecorationTheme gmInnerInputTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xffc5a05f), width: 1.2),
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(
      color: gmNavy,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    ),
    floatingLabelStyle: const TextStyle(color: gmNavy),
    hintStyle: const TextStyle(color: Color(0xff6b7480)),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: gmRed, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
  );
}
