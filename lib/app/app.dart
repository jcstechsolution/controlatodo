import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/settings_provider.dart';
import 'routes.dart';
import 'theme.dart';

/// Widget raíz de ControlaTodo: registra los providers globales y configura
/// MaterialApp.router con el enrutamiento basado en el estado de sesión.
class ControlaTodoApp extends StatelessWidget {
  const ControlaTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (_) => PaymentProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? PaymentProvider();
            provider.bind(auth.firebaseUser?.uid);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
          create: (_) => SettingsProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? SettingsProvider();
            provider.bind(auth.firebaseUser?.uid);
            return provider;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.read<AuthProvider>();
          final router = buildRouter(authProvider);
          final themeMode = context.watch<SettingsProvider>().settings.themeModeEnum;
          return MaterialApp.router(
            title: 'ControlaTodo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
