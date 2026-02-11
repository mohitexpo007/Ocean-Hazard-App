import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

final ValueNotifier<Locale?> appLocale = ValueNotifier<Locale?>(null);

Future<void> loadSavedLocale() async {
  final box = Hive.box('app_settings');
  final code = box.get('localeCode') as String?;
  if (code != null && code.isNotEmpty) {
    appLocale.value = Locale(code);
  }
}

Future<void> saveLocale(Locale locale) async {
  final box = Hive.box('app_settings');
  await box.put('localeCode', locale.languageCode);
  appLocale.value = locale;
}
