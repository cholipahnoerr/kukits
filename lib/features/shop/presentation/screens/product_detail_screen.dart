import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/product_model.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  int _imageIndex = 0;
  bool _descExpanded = false;
  bool _toastVisible = false;

  ProductModel get p => widget.product;

  void _increment() {
    if (_qty < p.stock) setState(() => _qty++);
  }

  void _decrement() {
    if (_qty > 1) setState(() => _qty--);
  }

  void _addToCart(BuildContext context) {
    for (var i = 0; i < _qty; i++) {
      context.read<CartBloc>().add(CartAddItem(p));
    }
    setState(() => _toastVisible = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _ImageSection(
                product: p,
                imageIndex: _imageIndex,
                onIndexChanged: (i) => setState(() => _imageIndex = i),
              )),
              SliverToBoxAdapter(child: _ContentCard(
                product: p,
                descExpanded: _descExpanded,
                onToggleDesc: () => setState(() => _descExpanded = !_descExpanded),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
          // Cart toast
          Positioned(
            bottom: 16,
            left: 24,
            right: 24,
            child: AnimatedOpacity(
              opacity: _toastVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_toastVisible,
                child: GestureDetector(
                  onTap: () => context.push(RouteNames.cart),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$_qty × ${p.name} ditambahkan ke keranjang',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                          ),
                        ),
                        Text(
                          'Lihat',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Back + cart buttons overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleNavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  BlocBuilder<CartBloc, CartState>(
                    builder: (context, state) {
                      final count = state.cart.totalItems;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _CircleNavButton(
                            icon: Icons.shopping_bag_outlined,
                            onTap: () => context.push(RouteNames.cart),
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: p.stock > 0
          ? _BottomBar(
              product: p,
              qty: _qty,
              onDecrement: _decrement,
              onIncrement: _increment,
              onAddToCart: () => _addToCart(context),
            )
          : _OutOfStockBar(),
    );
  }
}

class _CircleNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x142D3436), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 17, color: AppColors.primaryDark),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final ProductModel product;
  final int imageIndex;
  final ValueChanged<int> onIndexChanged;

  const _ImageSection({
    required this.product,
    required this.imageIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.imageUrls;
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image / placeholder
          images.isNotEmpty
              ? PageView.builder(
                  itemCount: images.length,
                  onPageChanged: onIndexChanged,
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: const Color(0xFFF0EDE6)),
                    errorWidget: (_, _, _) => _PlaceholderImg(),
                  ),
                )
              : _PlaceholderImg(),
          // Gradient overlay bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          // Dot indicators
          if (images.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final active = i == imageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0EDE6),
      child: const Center(
        child: Icon(Icons.kitchen_rounded, size: 72, color: AppColors.divider),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ProductModel product;
  final bool descExpanded;
  final VoidCallback onToggleDesc;

  const _ContentCard({
    required this.product,
    required this.descExpanded,
    required this.onToggleDesc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + sold row
          Row(
            children: [
              _CategoryChip(label: product.category),
              const SizedBox(width: 8),
              if (product.sold > 0) _SoldBadge(sold: product.sold),
            ],
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            product.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          // Price + stock row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.formattedPrice,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              _StockInfo(stock: product.stock),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // Stats row
          _StatsRow(product: product),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // Description
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deskripsi Produk',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              GestureDetector(
                onTap: onToggleDesc,
                child: Text(
                  descExpanded ? 'Sembunyikan' : 'Selengkapnya',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: descExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              product.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              product.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SoldBadge extends StatelessWidget {
  final int sold;
  const _SoldBadge({required this.sold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            '$sold terjual',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockInfo extends StatelessWidget {
  final int stock;
  const _StockInfo({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isLow = stock > 0 && stock <= 5;
    final isEmpty = stock == 0;
    final color = isEmpty
        ? AppColors.error
        : isLow
            ? AppColors.accent
            : AppColors.primary;

    return Row(
      children: [
        Icon(
          isEmpty
              ? Icons.remove_circle_outline_rounded
              : isLow
                  ? Icons.warning_amber_rounded
                  : Icons.inventory_2_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          isEmpty ? 'Stok habis' : 'Stok $stock',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ProductModel product;
  const _StatsRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.inventory_2_outlined,
            label: 'Stok',
            value: '${product.stock}',
          ),
        ),
        Container(width: 1, height: 36, color: AppColors.divider),
        Expanded(
          child: _StatItem(
            icon: Icons.local_fire_department_rounded,
            label: 'Terjual',
            value: '${product.sold}',
          ),
        ),
        Container(width: 1, height: 36, color: AppColors.divider),
        Expanded(
          child: _StatItem(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value: product.category[0].toUpperCase() + product.category.substring(1),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final ProductModel product;
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;

  const _BottomBar({
    required this.product,
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              // Quantity stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrement,
                      active: qty > 1,
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$qty',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrement,
                      active: qty < product.stock,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Add to cart button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddToCart,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text('Tambah ke Keranjang'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _StepperButton({required this.icon, required this.onTap, required this.active});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        width: 40,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.primary : AppColors.divider,
        ),
      ),
    );
  }
}

class _OutOfStockBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.divider,
              disabledBackgroundColor: AppColors.divider,
              disabledForegroundColor: AppColors.textSecondary,
            ),
            child: Text(
              'Stok Habis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
