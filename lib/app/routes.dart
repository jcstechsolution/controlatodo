import 'package:go_router/go_router.dart';

import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/home/home_shell.dart';
import '../features/payments/payment_detail_screen.dart';
import '../features/payments/payment_form_screen.dart';
import '../features/premium/premium_screen.dart';
import '../models/payment_model.dart';
import '../providers/auth_provider.dart';

/// Nombres de ruta centralizados para evitar strings mágicos repetidos.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const newPayment = '/payments/new';
  static const paymentDetail = '/payments/:id';
  static const editPayment = '/payments/:id/edit';
  static const premium = '/premium';

  static String paymentDetailPath(String id) => '/payments/$id';
  static String editPaymentPath(String id) => '/payments/$id/edit';
}

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final location = state.matchedLocation;

      const publicRoutes = {
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      };

      if (status == AuthStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuthenticated = status == AuthStatus.authenticated;

      if (!isAuthenticated && !publicRoutes.contains(location)) {
        return AppRoutes.welcome;
      }

      if (isAuthenticated &&
          (publicRoutes.contains(location) || location == AppRoutes.splash)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: AppRoutes.newPayment,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentFormScreen(
            initialName: extra?['name'] as String?,
            initialAmount: extra?['amount'] as double?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PaymentDetailScreen(paymentId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.editPayment,
        builder: (context, state) {
          final payment = state.extra as Payment?;
          return PaymentFormScreen(existingPayment: payment);
        },
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumScreen(),
      ),
    ],
  );
}
