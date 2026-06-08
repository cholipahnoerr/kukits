import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shop/domain/product_model.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            if (state.products.isEmpty)
              _EmptyProducts(
                onAdd: () => _showProductForm(context, null),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                itemCount: state.products.length,
                itemBuilder: (context, i) =>
                    _ProductTile(product: state.products[i]),
              ),
            Positioned(
              bottom: 20,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'addProduct',
                backgroundColor: AppColors.accent,
                onPressed: () => _showProductForm(context, null),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductForm(BuildContext context, ProductModel? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBloc>(),
        child: _ProductFormSheet(existing: product),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyProducts({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada produk',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tambahkan produk pertamamu',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Tambah Produk',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  const _ProductTile({required this.product});

  Color get _stockColor {
    if (product.stock == 0) return AppColors.error;
    if (product.stock < 5) return const Color(0xFFE67E22);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x082D3436), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                      product.imageUrls.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _ImagePlaceholder(),
                    )
                  : _ImagePlaceholder(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!product.isActive)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Text(
                            'Nonaktif',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.formattedPrice,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Stok: ${product.stock}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _stockColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${product.sold} terjual',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            Column(
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  color: AppColors.primary,
                  onTap: () => _showForm(context, product),
                ),
                const SizedBox(height: 6),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onTap: () => _confirmDelete(context, product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, ProductModel existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBloc>(),
        child: _ProductFormSheet(existing: existing),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus Produk?',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
        content: Text(
          '"${product.name}" akan dihapus permanen.',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminBloc>().add(AdminDeleteProduct(product.id));
              Navigator.pop(context);
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.image_not_supported_outlined,
          size: 24, color: AppColors.textSecondary),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Product Form Sheet ────────────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  final ProductModel? existing;
  const _ProductFormSheet({this.existing});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  String _category = 'kukusan';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '');
    _category = p?.category ?? 'kukusan';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: int.parse(_priceCtrl.text),
      stock: int.parse(_stockCtrl.text),
      imageUrls: widget.existing?.imageUrls ?? [],
      category: _category,
      isActive: widget.existing?.isActive ?? true,
      sold: widget.existing?.sold ?? 0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    context
        .read<AdminBloc>()
        .add(AdminSaveProduct(product: product, isNew: !_isEdit));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEdit
                          ? Icons.edit_outlined
                          : Icons.add_business_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Produk' : 'Tambah Produk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 0),
            const SizedBox(height: 20),
            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormField(
                      controller: _nameCtrl,
                      label: 'Nama Produk',
                      prefixIcon: Icons.label_outline_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    _FormField(
                      controller: _descCtrl,
                      label: 'Deskripsi',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            controller: _priceCtrl,
                            label: 'Harga (Rp)',
                            prefixIcon: Icons.sell_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib';
                              if (int.tryParse(v) == null) return 'Angka';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            controller: _stockCtrl,
                            label: 'Stok',
                            prefixIcon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib';
                              if (int.tryParse(v) == null) return 'Angka';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Category selector
                    _CategorySelector(
                      value: _category,
                      onChanged: (v) => setState(() => _category = v),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: Icon(
                          _isEdit ? Icons.check_rounded : Icons.add_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.primaryDark),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textSecondary),
        prefixIconConstraints: const BoxConstraints(minWidth: 46),
        labelStyle:
            GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CategorySelector({required this.value, required this.onChanged});

  static const _options = [
    ('kukusan', 'Kukusan', Icons.rice_bowl_outlined),
    ('paket', 'Paket', Icons.lunch_dining_outlined),
    ('makanan', 'Makanan', Icons.restaurant_outlined),
    ('minuman', 'Minuman', Icons.local_drink_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: _options.map((opt) {
            final (val, label, icon) = opt;
            final isSelected = value == val;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(
                    right: val == 'minuman' ? 0 : 8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
