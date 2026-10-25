import 'package:flutter/material.dart';

const gold = Color(0xff946A29),
    carbon = Color(0xff171715),
    ivory = Color(0xffFAF9F6);
ThemeData gmTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: gold,
    surface: ivory,
    primary: gold,
    onPrimary: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ivory,
    fontFamily: 'DM Sans',
    appBarTheme: const AppBarTheme(
      backgroundColor: ivory,
      foregroundColor: carbon,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffDED5C8)),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Playfair Display',
        fontWeight: FontWeight.w600,
        fontSize: 34,
        color: carbon,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Playfair Display',
        fontWeight: FontWeight.w600,
        fontSize: 28,
        color: carbon,
      ),
    ),
  );
}

class Brand extends StatelessWidget {
  final bool large;
  const Brand({super.key, this.large = false});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'G y M Melacampos',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'G',
                style: TextStyle(color: Color(0xffD81E24)),
              ),
              TextSpan(
                text: '&M',
                style: TextStyle(
                  color: const Color(0xff15357E),
                  fontSize: large ? 42 : 27,
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w900,
            fontSize: large ? 48 : 30,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Melacampos',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: large ? 25 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xff15357E),
              ),
            ),
            Text(
              'Mármol · Granito · Cuarzo',
              style: TextStyle(
                fontSize: large ? 11 : 9,
                color: const Color(0xff6C6963),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class Note extends StatelessWidget {
  final String text;
  final IconData icon;
  const Note(this.text, {super.key, this.icon = Icons.info_outline});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xff6C6963), height: 1.5),
          ),
        ),
      ],
    ),
  );
}

void showError(BuildContext c, Object e) {
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(
      content: Text(e.toString().replaceFirst('Exception: ', '')),
      duration: const Duration(seconds: 6),
    ),
  );
}
