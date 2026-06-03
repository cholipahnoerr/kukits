import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              const Center(
                child: Text('Belum ada produk',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: state.products.length,
                itemBuilder: (context, i) =>
                    _ProductTile(product: state.products[i]),
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'addProduct',
                onPressed: () => _showProductForm(context, null),
                child: const Icon(Icons.add),
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
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBloc>(),
        child: _ProductFormSheet(existing: product),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: product.imageUrls.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrls.first,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary),
                ),
              )
            : const Icon(Icons.image_not_supported,
                size: 40, color: AppColors.textSecondary),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${product.formattedPrice} • Stok: ${product.stock}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary),
              onPressed: () => _showForm(context, product),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error),
              onPressed: () => _confirmDelete(context, product),
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
        title: const Text('Hapus Produk'),
        content: Text('Hapus "${product.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              context
                  .read<AdminBloc>()
                  .add(AdminDeleteProduct(product.id));
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

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

    context.read<AdminBloc>().add(
          AdminSaveProduct(
              product: product, isNew: widget.existing == null),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Tambah Produk' : 'Edit Produk',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nama Produk *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Deskripsi *'),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Harga *', prefixText: 'Rp '),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (int.tryParse(v) == null) return 'Harus angka';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Stok *'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (int.tryParse(v) == null) return 'Harus angka';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: const [
                DropdownMenuItem(
                    value: 'kukusan', child: Text('Kukusan')),
                DropdownMenuItem(
                    value: 'makanan', child: Text('Makanan')),
                DropdownMenuItem(
                    value: 'minuman', child: Text('Minuman')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
