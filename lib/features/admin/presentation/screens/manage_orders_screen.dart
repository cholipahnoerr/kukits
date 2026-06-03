import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../shop/domain/order_model.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading && state.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.orders.isEmpty) {
          return const Center(
            child: Text('Belum ada pesanan',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.orders.length,
          itemBuilder: (context, i) =>
              _OrderCard(order: state.orders[i]),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

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
    final auth = context.read<AuthBloc>().state;
    final adminUid =
        auth is AuthAuthenticated ? auth.user.uid : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    border:
                        Border.all(color: _statusColor(order.status)),
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
            Text(order.formattedTotal,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            Text(
              '${order.items.length} item • ${order.deliveryMethod}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            if (order.paymentProofUrl != null &&
                order.status == 'dibayar') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showProof(context, order.paymentProofUrl!),
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('Lihat Bukti',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.read<AdminBloc>().add(
                            AdminConfirmPayment(
                                orderId: order.id, adminUid: adminUid),
                          ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Konfirmasi',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
            if (order.status == 'diproses') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: order.status,
                decoration: const InputDecoration(
                  labelText: 'Update Status',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'diproses', child: Text('Diproses')),
                  DropdownMenuItem(
                      value: 'dikirim', child: Text('Dikirim')),
                  DropdownMenuItem(
                      value: 'selesai', child: Text('Selesai')),
                ],
                onChanged: (v) {
                  if (v != null && v != order.status) {
                    context.read<AdminBloc>().add(
                          AdminUpdateOrderStatus(
                              orderId: order.id, status: v),
                        );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProof(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Pembayaran'),
              leading: const CloseButton(),
              automaticallyImplyLeading: false,
            ),
            Image.network(url, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
