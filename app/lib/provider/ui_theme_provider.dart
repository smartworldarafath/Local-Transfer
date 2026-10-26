import 'dart:async';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UiTheme {
  oneUi,
  aiUi,
  liquidGlass,
}

extension UiThemeExt on UiTheme {
  String get label {
    switch (this) {
      case UiTheme.oneUi:
        return 'One Ui';
      case UiTheme.aiUi:
        return 'Ai Ui';
      case UiTheme.liquidGlass:
        return 'Liquid Glass';
    }
  }
}

class UiThemeNotifier extends Notifier<UiTheme> {
  static const _prefKey = 'ls_ui_theme';

  @override
  UiTheme init() {
    unawaited(_load());
    return UiTheme.oneUi;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_prefKey);
    if (savedName != null) {
      for (final value in UiTheme.values) {
        if (value.name == savedName) {
          state = value;
          return;
        }
      }
    }
  }

  Future<void> setUiTheme(UiTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, theme.name);
  }
}

final uiThemeProvider = NotifierProvider<UiThemeNotifier, UiTheme>(
  (ref) => UiThemeNotifier(),
);
