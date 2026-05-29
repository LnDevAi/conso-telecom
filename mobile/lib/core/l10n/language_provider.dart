import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';
import 'app_strings_fr.dart';
import 'app_strings_en.dart';

const _storageKey = 'conso_telecom_lang';

class LanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('fr');

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == 'en') state = const Locale('en');
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'fr' ? const Locale('en') : const Locale('fr');
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, next.languageCode);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(
  LanguageNotifier.new,
);

final translationsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(languageProvider);
  return locale.languageCode == 'en' ? AppStringsEn() : AppStringsFr();
});
