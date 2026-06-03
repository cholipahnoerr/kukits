import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import 'manage_orders_screen.dart';
import 'manage_products_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<AdminBloc>()
      ..add(const AdminLoadOrders())
      ..add(const AdminLoadProducts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Pesanan'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Produk'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ManageOrdersScreen(),
          ManageProductsScreen(),
        ],
      ),
    );
  }
}
