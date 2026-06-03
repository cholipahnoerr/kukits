import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'route_names.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/shop/presentation/screens/product_list_screen.dart';
import '../../features/shop/presentation/screens/product_detail_screen.dart';
import '../../features/shop/presentation/screens/cart_screen.dart';
import '../../features/shop/presentation/screens/checkout_screen.dart';
import '../../features/shop/presentation/screens/upload_bukti_screen.dart';
import '../../features/shop/presentation/screens/order_status_screen.dart';
import '../../features/shop/presentation/screens/order_history_screen.dart';
import '../../features/shop/domain/product_model.dart';
import '../../features/nutrition/presentation/screens/nutrition_dashboard_screen.dart';
import '../../features/nutrition/presentation/screens/add_food_screen.dart';
import '../../features/nutrition/presentation/screens/food_history_screen.dart';
import '../../features/nutrition/domain/food_log_model.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/scanner/presentation/screens/scan_result_screen.dart';
import '../../features/scanner/presentation/bloc/scanner_state.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/planner/presentation/screens/add_meal_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  _AuthChangeNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: RouteNames.login,
  refreshListenable: _AuthChangeNotifier(),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation == RouteNames.login ||
        state.matchedLocation == RouteNames.register ||
        state.matchedLocation == RouteNames.forgotPassword;

    if (!isLoggedIn && !isAuthRoute) return RouteNames.login;
    if (isLoggedIn && isAuthRoute) return RouteNames.home;
    return null;
  },
  routes: [
    GoRoute(
      path: RouteNames.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.register,
      builder: (_, _) => const RegisterScreen(),
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      builder: (_, _) => const ForgotPasswordScreen(),
    ),

    // Main shell with 5-tab bottom navigation
    ShellRoute(
      builder: (_, _, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.home,
          builder: (_, _) => const ProductListScreen(),
        ),
        GoRoute(
          path: RouteNames.nutrition,
          builder: (_, _) => const NutritionDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.scanner,
          builder: (_, _) => const ScannerScreen(),
        ),
        GoRoute(
          path: RouteNames.planner,
          builder: (_, _) => const PlannerScreen(),
        ),
        GoRoute(
          path: RouteNames.profile,
          builder: (_, _) => const ProfileScreen(),
        ),
      ],
    ),

    // Full-screen routes outside shell
    GoRoute(
      path: RouteNames.editProfile,
      builder: (_, _) => const EditProfileScreen(),
    ),
    GoRoute(
      path: RouteNames.productDetail,
      builder: (_, state) {
        final product = state.extra as ProductModel;
        return ProductDetailScreen(product: product);
      },
    ),
    GoRoute(
      path: RouteNames.cart,
      builder: (_, _) => const CartScreen(),
    ),
    GoRoute(
      path: RouteNames.checkout,
      builder: (_, _) => const CheckoutScreen(),
    ),
    GoRoute(
      path: RouteNames.uploadBukti,
      builder: (_, state) {
        final orderId = state.extra as String;
        return UploadBuktiScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: RouteNames.orderStatus,
      builder: (_, state) {
        final orderId = state.extra as String;
        return OrderStatusScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: RouteNames.orderHistory,
      builder: (_, _) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: RouteNames.addFood,
      builder: (_, state) {
        final mealType = state.extra as String?;
        return AddFoodScreen(initialMealType: mealType);
      },
    ),
    GoRoute(
      path: RouteNames.editFood,
      builder: (_, state) {
        final log = state.extra as FoodLogModel;
        return AddFoodScreen(existing: log);
      },
    ),
    GoRoute(
      path: RouteNames.foodHistory,
      builder: (_, _) => const FoodHistoryScreen(),
    ),
    GoRoute(
      path: RouteNames.addMeal,
      builder: (_, state) {
        final date = state.extra as String;
        return AddMealScreen(date: date);
      },
    ),
    GoRoute(
      path: RouteNames.scanResult,
      builder: (_, state) {
        final scanState = state.extra as ScannerSuccess;
        return ScanResultScreen(scanState: scanState);
      },
    ),
    GoRoute(
      path: RouteNames.admin,
      builder: (_, _) => const AdminDashboardScreen(),
    ),
  ],
);

class _MainShell extends StatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const _tabs = [
    (icon: Icons.store_outlined, label: 'Toko', path: RouteNames.home),
    (
      icon: Icons.restaurant_outlined,
      label: 'Nutrisi',
      path: RouteNames.nutrition
    ),
    (
      icon: Icons.camera_enhance_outlined,
      label: 'Scan AI',
      path: RouteNames.scanner
    ),
    (
      icon: Icons.calendar_month_outlined,
      label: 'Planner',
      path: RouteNames.planner
    ),
    (
      icon: Icons.person_outlined,
      label: 'Profil',
      path: RouteNames.profile
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          context.go(_tabs[i].path);
        },
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
