import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/product_model.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: AppColors.background),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.background,
                        child: const Icon(Icons.image_not_supported, size: 64),
                      ),
                    )
                  : Container(
                      color: AppColors.background,
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(product.category),
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock} • Terjual: ${product.sold}',
                    style:
                        const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Deskripsi',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: product.stock > 0
              ? CustomButton(
                  label: 'Tambah ke Keranjang',
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  onPressed: () {
                    context.read<CartBloc>().add(CartAddItem(product));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} ditambahkan ke keranjang'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                )
              : const CustomButton(
                  label: 'Stok Habis',
                  onPressed: null,
                ),
        ),
      ),
    );
  }
}
