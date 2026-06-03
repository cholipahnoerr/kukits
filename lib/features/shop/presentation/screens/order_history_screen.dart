import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final Stream<QuerySnapshot> _stream;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      _stream = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: auth.user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
      _ready = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: !_ready
          ? const Center(child: Text('Tidak terautentikasi'))
          : StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                final orders = snapshot.data?.docs
                        .map(OrderModel.fromFirestore)
                        .toList() ??
                    [];

                if (orders.isEmpty) {
                  return const Center(
                    child: Text('Belum ada pesanan',
                        style: TextStyle(
                            color: AppColors.textSecondary)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) =>
                      _OrderHistoryCard(order: orders[i]),
                );
              },
            ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  const _OrderHistoryCard({required this.order});

  Color _statusColor(String status) => switch (status) {
        'menunggu_pembayaran' => Colors.orange,
        'dibayar' => Colors.blue,
        'diproses' => AppColors.primary,
        'dikirim' => Colors.purple,
        'selesai' => Colors.grey,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push(RouteNames.orderStatus, extra: order.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.orderId,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _statusColor(order.status)),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: _statusColor(order.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${order.items.length} item • ${order.formattedTotal}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
