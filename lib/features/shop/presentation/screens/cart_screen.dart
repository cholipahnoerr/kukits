import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/custom_button.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final cart = state.cart;
          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 72, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Keranjang masih kosong',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.product.imageUrls.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.product.imageUrls.first,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 64,
                                      height: 64,
                                      color: AppColors.background,
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.product.formattedPrice,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            _QuantityControl(
                              quantity: item.quantity,
                              onDecrement: () => context.read<CartBloc>().add(
                                    CartUpdateQuantity(
                                        item.product.id, item.quantity - 1),
                                  ),
                              onIncrement: () => context.read<CartBloc>().add(
                                    CartUpdateQuantity(
                                        item.product.id, item.quantity + 1),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            cart.formattedTotal,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Checkout (${cart.totalItems} item)',
                        onPressed: () => context.push(RouteNames.checkout),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onDecrement,
          icon: Icon(
            quantity <= 1 ? Icons.delete_outline : Icons.remove_circle_outline,
            color: quantity <= 1 ? AppColors.error : AppColors.primary,
          ),
          visualDensity: VisualDensity.compact,
        ),
        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
