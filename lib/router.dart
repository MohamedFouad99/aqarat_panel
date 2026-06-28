import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/properties_list_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'public/about_page.dart';
import 'public/account_page.dart';
import 'public/advertiser_page.dart';
import 'public/compare_page.dart';
import 'public/map_page.dart';
import 'public/favorites_page.dart';
import 'public/home_page.dart';
import 'public/my_subscription_page.dart';
import 'public/notifications_page.dart';
import 'public/packages_page.dart';
import 'public/property_detail_page.dart';
import 'public/request_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, state) => HomePage(
        initialListing: state.uri.queryParameters['listingType'],
        initialType: state.uri.queryParameters['type'],
        initialQuery: state.uri.queryParameters['q'],
      ),
    ),
    GoRoute(
      path: '/property/:id',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        // key بالـ id عشان الصفحة تتحدّث عند الانتقال من عقار لعقار
        return PropertyDetailPage(key: ValueKey(id), propertyId: id);
      },
    ),
    GoRoute(path: '/packages', builder: (_, _) => const PackagesPage()),
    GoRoute(path: '/request', builder: (_, _) => const RequestPage()),
    GoRoute(path: '/map', builder: (_, _) => const MapPage()),
    GoRoute(path: '/about', builder: (_, _) => const AboutPage()),
    GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
    GoRoute(path: '/compare', builder: (_, _) => const ComparePage()),
    GoRoute(path: '/favorites', builder: (_, _) => const FavoritesPage()),
    GoRoute(
        path: '/notifications', builder: (_, _) => const NotificationsPage()),
    GoRoute(
        path: '/my-subscription',
        builder: (_, _) => const MySubscriptionPage()),
    GoRoute(
      path: '/advertiser/:name',
      builder: (_, state) =>
          AdvertiserPage(name: Uri.decodeComponent(state.pathParameters['name']!)),
    ),
    // منطقة المعلنين/الأدمن — خلف تسجيل الدخول
    GoRoute(path: '/admin', builder: (_, _) => const AdminGate()),
  ],
);

/// بوابة الأدمن: تعرض الدخول/التسجيل أو لوحة التحكم حسب حالة تسجيل الدخول.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  bool _showSignup = false;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder(
      stream: auth.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) return const PropertiesListScreen();
        return _showSignup
            ? SignupScreen(
                onSwitchToLogin: () => setState(() => _showSignup = false))
            : LoginScreen(
                onSwitchToSignup: () => setState(() => _showSignup = true));
      },
    );
  }
}
