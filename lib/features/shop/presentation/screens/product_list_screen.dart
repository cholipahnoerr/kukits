import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/product_model.dart';
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _selectedCategory;

  static const _categories = ['Semua', 'kukusan', 'aksesori', 'bahan'];

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(const ShopLoadProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Kukits'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              final count = state.cart.totalItems;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.push(RouteNames.cart),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.secondary,
                        child: Text(
                          '$count',
                          style: const TextStyle(fontSize: 10, color: Colors.black),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoryFilter(
            selected: _selectedCategory,
            categories: _categories,
            onChanged: (cat) {
              setState(() => _selectedCategory = cat == 'Semua' ? null : cat);
              context.read<ShopBloc>().add(
                    ShopLoadProducts(category: cat == 'Semua' ? null : cat),
                  );
            },
          ),
          Expanded(
            child: BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) {
                if (state is ShopLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ShopError) {
                  return Center(child: Text(state.message));
                }
                if (state is ShopLoaded) {
                  if (state.products.isEmpty) {
                    return const Center(
                      child: Text('Belum ada produk tersedia'),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (_, i) =>
                        _ProductCard(product: state.products[i]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  const _CategoryFilter({
    required this.selected,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected =
              (selected == null && cat == 'Semua') || selected == cat;
          return FilterChip(
            label: Text(cat == 'kukusan'
                ? 'Kukusan'
                : cat == 'aksesori'
                    ? 'Aksesori'
                    : cat == 'bahan'
                        ? 'Bahan'
                        : cat),
            selected: isSelected,
            onSelected: (_) => onChanged(cat),
            selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.productDetail, extra: product),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, _) => Container(color: AppColors.background),
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.image_not_supported, size: 48),
                    )
                  : Container(
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stok: ${product.stock}',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}