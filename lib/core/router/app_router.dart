import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/public_menu/screens/order_confirm_screen.dart';
import '../../features/public_menu/screens/order_success_screen.dart';
import '../../features/public_menu/screens/public_menu_screen.dart';
import '../../features/public_menu/screens/qr_scan_screen.dart';
import '../../features/restaurant/screens/item_form_screen.dart';
import '../../features/restaurant/screens/menu_detail_screen.dart';
import '../../features/restaurant/screens/qr_display_screen.dart';

bool _isPublicPath(String loc) =>
    loc == '/scan' || loc.startsWith('/menu/');

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      if (auth.status == AuthStatus.loading) {
        return loc == '/splash' ? null : '/splash';
      }

      if (auth.status == AuthStatus.unauthenticated) {
        if (loc == '/login' || loc == '/register') return null;
        if (_isPublicPath(loc)) return null;
        return '/login';
      }

      // Authenticated — auth sayfalarından çık
      if (loc == '/splash' || loc == '/login' || loc == '/register') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Auth
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Admin (authenticated)
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/menus/:menuId',
        builder: (_, state) => MenuDetailScreen(
          menuId: state.pathParameters['menuId']!,
          menuName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/items/new',
        builder: (_, state) => ItemFormScreen(
          categoryId: state.uri.queryParameters['categoryId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/items/:itemId/edit',
        builder: (_, state) => ItemFormScreen(
          categoryId: state.uri.queryParameters['categoryId'] ?? '',
          itemId: state.pathParameters['itemId'],
        ),
      ),
      GoRoute(path: '/qr', builder: (_, __) => const QRDisplayScreen()),

      // Public (no auth required)
      GoRoute(path: '/scan', builder: (_, __) => const QRScanScreen()),
      GoRoute(
        path: '/menu/:slug',
        builder: (_, state) => PublicMenuScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/menu/:slug/confirm',
        builder: (_, state) => OrderConfirmScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/menu/:slug/success',
        builder: (_, state) => OrderSuccessScreen(
          slug: state.pathParameters['slug']!,
          extraJson: state.extra as String?,
        ),
      ),
    ],
  );
});
