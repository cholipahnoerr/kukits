import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/order_repository.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  String _deliveryMethod = 'transfer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.address != null) {
      _addressCtrl.text = authState.user.address!;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final cart = context.read<CartBloc>().state.cart;
      final method = _deliveryMethod;
      final order = await OrderRepository().createOrder(
        userId: authState.user.uid,
        cart: cart,
        deliveryMethod: method,
        deliveryAddress: _addressCtrl.text.trim(),
      );

      if (!mounted) return;
      context.read<CartBloc>().add(const CartClear());
      if (method == 'transfer') {
        context.pushReplacement(RouteNames.uploadBukti, extra: order.id);
      } else {
        context.pushReplacement(RouteNames.orderStatus, extra: order.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pesanan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final cart = state.cart;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionTitle('Ringkasan Pesanan'),
                const SizedBox(height: 8),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name} x${item.quantity}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.product.formattedPrice,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
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
                      cart.formattedTotal,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionTitle('Alamat Pengiriman'),
                const SizedBox(height: 8),
                CustomTextField(
                  label: 'Alamat Lengkap',
                  controller: _addressCtrl,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  maxLines: 3,
                  validator: Validators.required,
                ),
                const SizedBox(height: 24),
                _SectionTitle('Metode Pembayaran'),
                const SizedBox(height: 8),
                _PaymentMethodTile(
                  value: 'transfer',
                  groupValue: _deliveryMethod,
                  title: 'Transfer Bank',
                  subtitle: 'Upload bukti transfer setelah checkout',
                  icon: Icons.account_balance_outlined,
                  onChanged: (v) => setState(() => _deliveryMethod = v!),
                ),
                const SizedBox(height: 8),
                _PaymentMethodTile(
                  value: 'cod',
                  groupValue: _deliveryMethod,
                  title: 'COD (Bayar di Tempat)',
                  subtitle: 'Bayar saat barang tiba',
                  icon: Icons.payments_outlined,
                  onChanged: (v) => setState(() => _deliveryMethod = v!),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: _deliveryMethod == 'transfer'
                      ? 'Pesan & Upload Bukti'
                      : 'Pesan Sekarang',
                  isLoading: _isLoading,
                  onPressed: _placeOrder,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primary : AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
