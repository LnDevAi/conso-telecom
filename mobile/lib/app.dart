import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/language_provider.dart';

class ConsoTelecomApp extends ConsumerStatefulWidget {
  const ConsoTelecomApp({super.key});

  @override
  ConsumerState<ConsoTelecomApp> createState() => _ConsoTelecomAppState();
}

class _ConsoTelecomAppState extends ConsumerState<ConsoTelecomApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(languageProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'ConsoTélécom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [
        Locale('fr', 'BF'),
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
