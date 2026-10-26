import 'dart:async';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackgroundLook {
  defaultUi,
  white,
  grey,
  lightSkyblue,
  lightLemon,
  lightViolet,
}

extension BackgroundLookExt on BackgroundLook {
  String get label {
    switch (this) {
      case BackgroundLook.defaultUi:
        return 'Default (Current UI)';
      case BackgroundLook.white:
        return 'White';
      case BackgroundLook.grey:
        return 'Grey';
      case BackgroundLook.lightSkyblue:
        return 'Light skyblue';
      case BackgroundLook.lightLemon:
        return 'Light Lemon';
      case BackgroundLook.lightViolet:
        return 'Light Violet';
    }
  }

  Color swatch(bool isDark) {
    switch (this) {
      case BackgroundLook.defaultUi:
        return isDark ? const Color(0xFF1E222B) : const Color(0xFFF1F5F9);
      case BackgroundLook.white:
        return const Color(0xFFFFFFFF);
      case BackgroundLook.grey:
        return const Color(0xFF8E99A4);
      case BackgroundLook.lightSkyblue:
        return const Color(0xFF8CD1F7);
      case BackgroundLook.lightLemon:
        return const Color(0xFFD6F599);
      case BackgroundLook.lightViolet:
        return const Color(0xFFD1A7F8);
    }
  }

  Color? getScaffoldColor(bool isDark) {
    switch (this) {
      case BackgroundLook.defaultUi:
        return null;
      case BackgroundLook.white:
        return isDark ? const Color(0xFF14171C) : const Color(0xFFFFFFFF);
      case BackgroundLook.grey:
        return isDark ? const Color(0xFF1E2127) : const Color(0xFFF0F2F5);
      case BackgroundLook.lightSkyblue:
        return isDark ? const Color(0xFF101E29) : const Color(0xFFE8F4FA);
      case BackgroundLook.lightLemon:
        return isDark ? const Color(0xFF182215) : const Color(0xFFF4F9EB);
      case BackgroundLook.lightViolet:
        return isDark ? const Color(0xFF20182A) : const Color(0xFFF5EBFB);
    }
  }
}

class BackgroundLookNotifier extends Notifier<BackgroundLook> {
  static const _prefKey = 'ls_background_look';

  @override
  BackgroundLook init() {
    unawaited(_load());
    return BackgroundLook.defaultUi;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_prefKey);
    if (savedName != null) {
      for (final value in BackgroundLook.values) {
        if (value.name == savedName) {
          state = value;
          return;
        }
      }
    }
  }

  Future<void> setBackgroundLook(BackgroundLook look) async {
    state = look;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, look.name);
  }
}

final backgroundLookProvider = NotifierProvider<BackgroundLookNotifier, BackgroundLook>(
  (ref) => BackgroundLookNotifier(),
);
