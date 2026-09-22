import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_store.dart';

/// Owns light/dark/system selection and writes it through to preferences so
/// the choice survives a restart.
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.read(preferencesStoreProvider).readThemeMode();
    return _parse(stored);
  }

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref.read(preferencesStoreProvider).writeThemeMode(mode.name);
  }

  static ThemeMode _parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
