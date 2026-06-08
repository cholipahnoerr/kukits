import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
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
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _categories = ['Semua', 'kukusan', 'paket', 'makanan', 'minuman'];

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(const ShopLoadProducts());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> _filtered(List<ProductModel> products) {
    if (_searchQuery.isEmpty) return products;
    return products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(searchCtrl: _searchCtrl, onSearch: (q) => setState(() => _searchQuery = q)),
          _CategoryBar(
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
                if (state is ShopLoading) return _GridSkeleton();
                if (state is ShopError) return _ErrorView(message: state.message);
                if (state is ShopLoaded) {
                  final products = _filtered(state.products);
                  if (products.isEmpty) return _EmptyView(isSearch: _searchQuery.isNotEmpty);
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => _ProductCard(product: products[i]),
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

class _Header extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  const _Header({required this.searchCtrl, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toko Kukits',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'Produk kukusan pilihan untukmu',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    final count = state.cart.totalItems;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                            onPressed: () => context.push(RouteNames.cart),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearch,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari produk kukusan...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String? selected;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  const _CategoryBar({
    required this.selected,
    required this.categories,
    required this.onChanged,
  });

  String _label(String cat) {
    const map = {'kukusan': 'Kukusan', 'paket': 'Paket Menu', 'makanan': 'Makanan', 'minuman': 'Minuman'};
    return map[cat] ?? cat;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = (selected == null && cat == 'Semua') || selected == cat;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isSelected ? AppColors.primaryDark : AppColors.cardBorder,
                ),
              ),
              child: Text(
                _label(cat),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  bool get _isLowStock => product.stock > 0 && product.stock <= 5;
  bool get _isOutOfStock => product.stock == 0;
  bool get _isBestSeller => product.sold >= 10;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.productDetail, extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A2D3436),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: AppColors.background),
                            errorWidget: (_, _, _) => _ImagePlaceholder(),
                          )
                        : _ImagePlaceholder(),
                    // Badge
                    if (_isBestSeller || _isOutOfStock)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isOutOfStock
                                ? AppColors.textSecondary
                                : AppColors.accent,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Text(
                            _isOutOfStock ? 'Habis' : 'Terlaris',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.formattedPrice,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _isOutOfStock
                            ? Icons.remove_circle_outline_rounded
                            : _isLowStock
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded,
                        size: 12,
                        color: _isOutOfStock
                            ? AppColors.error
                            : _isLowStock
                                ? AppColors.accent
                                : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isOutOfStock
                            ? 'Stok habis'
                            : _isLowStock
                                ? 'Sisa ${product.stock}'
                                : 'Stok ${product.stock}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _isOutOfStock
                              ? AppColors.error
                              : _isLowStock
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
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

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0EDE6),
      child: const Center(
        child: Icon(Icons.kitchen_rounded, size: 40, color: AppColors.divider),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEDEAE2),
      highlightColor: const Color(0xFFFDFBF7),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isSearch;
  const _EmptyView({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.kitchen_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? 'Produk tidak ditemukan' : 'Belum ada produk',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Coba kata kunci lain'
                  : 'Produk akan segera hadir untukmu',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
