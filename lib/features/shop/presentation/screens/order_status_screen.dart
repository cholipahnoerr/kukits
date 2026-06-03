import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/order_repository.dart';
import '../../domain/order_model.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Pesanan')),
      body: StreamBuilder<OrderModel>(
        stream: OrderRepository().watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Pesanan tidak ditemukan'));
          }
          final order = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusHeader(order: order),
              const SizedBox(height: 24),
              _OrderTimeline(status: order.status),
              const SizedBox(height: 24),
              _OrderSummaryCard(order: order),
            ],
          );
        },
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final OrderModel order;
  const _StatusHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _statusIcon(order.status),
              size: 56,
              color: _statusColor(order.status),
            ),
            const SizedBox(height: 8),
            Text(
              order.statusLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(order.status),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              order.orderId,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) => switch (status) {
        'menunggu_pembayaran' => Icons.hourglass_empty,
        'dibayar' => Icons.check_circle_outline,
        'diproses' => Icons.inventory_2_outlined,
        'dikirim' => Icons.local_shipping_outlined,
        'selesai' => Icons.task_alt,
        _ => Icons.help_outline,
      };

  Color _statusColor(String status) => switch (status) {
        'menunggu_pembayaran' => Colors.orange,
        'dibayar' => Colors.blue,
        'diproses' => Colors.purple,
        'dikirim' => Colors.indigo,
        'selesai' => AppColors.primary,
        _ => AppColors.textSecondary,
      };
}

class _OrderTimeline extends StatelessWidget {
  final String status;
  const _OrderTimeline({required this.status});

  static const _steps = [
    ('menunggu_pembayaran', 'Menunggu Pembayaran'),
    ('dibayar', 'Pembayaran Dikonfirmasi'),
    ('diproses', 'Diproses'),
    ('dikirim', 'Dikirim'),
    ('selesai', 'Selesai'),
  ];

  int get _currentIndex =>
      _steps.indexWhere((s) => s.$1 == status);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perjalanan Pesanan',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final isDone = i <= _currentIndex;
              return _TimelineItem(
                label: step.$2,
                isDone: isDone,
                isLast: i == _steps.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isLast;

  const _TimelineItem({
    required this.label,
    required this.isDone,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: isDone ? AppColors.primary : AppColors.divider,
                child: Icon(
                  isDone ? Icons.check : Icons.circle,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppColors.primary : AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final OrderModel order;
  const _OrderSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Pesanan',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${item.productName} x${item.quantity}',
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('Rp ${_fmt(item.subtotal)}'),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  order.formattedTotal,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Metode: ${order.deliveryMethod == 'transfer' ? 'Transfer Bank' : 'COD'}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              'Alamat: ${order.deliveryAddress}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}
