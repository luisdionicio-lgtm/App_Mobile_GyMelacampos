import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';

enum Accent { gold, blue, forest }

class AppPreferences extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;
  Accent accent = Accent.gold;
  bool reduceMotion = false;
  final Set<String> favorites = {};
  static const key = 'gm.preferences.v1';
  Color get seed => switch (accent) {
    Accent.gold => const Color(0xff946A29),
    Accent.blue => const Color(0xff15357E),
    Accent.forest => const Color(0xff29634C),
  };
  Future<void> load() async {
    final value = await Api.storage.read(key: key);
    if (value == null) return;
    try {
      final json = jsonDecode(value);
      mode = ThemeMode.values.byName(json['mode']);
      accent = Accent.values.byName(json['accent']);
      reduceMotion = json['reduceMotion'] ?? false;
      favorites.addAll((json['favorites'] as List? ?? []).cast<String>());
    } catch (_) {
      /* Unknown older settings fall back to defaults. */
    }
  }

  Future<void> _save() async {
    notifyListeners();
    await Api.storage.write(
      key: key,
      value: jsonEncode({
        'mode': mode.name,
        'accent': accent.name,
        'reduceMotion': reduceMotion,
        'favorites': favorites.toList(),
      }),
    );
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    await _save();
  }

  Future<void> setAccent(Accent value) async {
    accent = value;
    await _save();
  }

  Future<void> setMotion(bool value) async {
    reduceMotion = value;
    await _save();
  }

  Future<void> toggleFavorite(String id) async {
    if (!favorites.remove(id)) favorites.add(id);
    await _save();
  }
}

class PreferencesScope extends InheritedNotifier<AppPreferences> {
  const PreferencesScope({
    super.key,
    required AppPreferences preferences,
    required super.child,
  }) : super(notifier: preferences);
  static AppPreferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferencesScope>()!.notifier!;
}
