import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/shop/presentation/bloc/cart_bloc.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';
import 'features/nutrition/presentation/bloc/nutrition_bloc.dart';
import 'features/planner/presentation/bloc/planner_bloc.dart';
import 'features/scanner/presentation/bloc/scanner_bloc.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';

class KukitsApp extends StatelessWidget {
  const KukitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(repository: AuthRepository())),
        BlocProvider(create: (_) => CartBloc()),
        BlocProvider(create: (_) => ShopBloc()),
        BlocProvider(create: (_) => NutritionBloc()),
        BlocProvider(create: (_) => PlannerBloc()),
        BlocProvider(create: (_) => ScannerBloc()),
        BlocProvider(create: (_) => AdminBloc()),
      ],
      child: MaterialApp.router(
        title: 'Kukits',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
