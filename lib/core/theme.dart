import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const gold = Color(0xff946A29),
    carbon = Color(0xff171715),
    ivory = Color(0xffFAF9F6);
const gmEase = Cubic(.23, 1, .32, 1);
ThemeData gmTheme({
  Brightness brightness = Brightness.light,
  Color seed = gold,
}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    surface: dark ? const Color(0xff171715) : ivory,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'DM Sans',
    scaffoldBackgroundColor: scheme.surface,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge!.copyWith(
        fontFamily: 'Playfair Display',
        fontWeight: FontWeight.w600,
        fontSize: 34,
        height: 1.12,
      ),
      headlineMedium: base.textTheme.headlineMedium!.copyWith(
        fontFamily: 'Playfair Display',
        fontWeight: FontWeight.w600,
        fontSize: 27,
        height: 1.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 0,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      height: 76,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class Brand extends StatelessWidget {
  final bool large;
  const Brand({super.key, this.large = false});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blue = dark ? const Color(0xff9BB8FF) : const Color(0xff15357E);
    return Semantics(
      label: 'G y M Melacampos',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'G',
                    style: TextStyle(
                      color: dark
                          ? const Color(0xffFF7479)
                          : const Color(0xffD81E24),
                    ),
                  ),
                  TextSpan(
                    text: '&M',
                    style: TextStyle(color: blue, fontSize: large ? 42 : 27),
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
                    color: blue,
                  ),
                ),
                Text(
                  'Mármol · Granito · Cuarzo',
                  style: TextStyle(
                    fontSize: large ? 11 : 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString().replaceFirst('Exception: ', '')),
      duration: const Duration(seconds: 6),
    ),
  );
}
