import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/order_repository.dart';

class UploadBuktiScreen extends StatefulWidget {
  final String orderId;
  const UploadBuktiScreen({super.key, required this.orderId});

  @override
  State<UploadBuktiScreen> createState() => _UploadBuktiScreenState();
}

class _UploadBuktiScreenState extends State<UploadBuktiScreen> {
  File? _imageFile;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _upload() async {
    if (_imageFile == null) return;
    setState(() => _isUploading = true);
    try {
      await OrderRepository().uploadPaymentProof(widget.orderId, _imageFile!);
      if (mounted) {
        context.pushReplacement(RouteNames.orderStatus, extra: widget.orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Bukti Transfer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.account_balance, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Transfer ke rekening berikut:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _BankInfo(bank: 'BCA', accountNo: '1234567890', name: 'Kukits Store'),
            _BankInfo(bank: 'Mandiri', accountNo: '0987654321', name: 'Kukits Store'),
            const SizedBox(height: 32),
            const Text('Foto Bukti Transfer',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isUploading ? null : () => _showPickerOptions(),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _imageFile != null
                        ? AppColors.primary
                        : AppColors.divider,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.background,
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: AppColors.textSecondary),
                          SizedBox(height: 8),
                          Text('Tap untuk pilih foto',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
              ),
            ),
            const Spacer(),
            CustomButton(
              label: 'Upload & Konfirmasi',
              isLoading: _isUploading,
              onPressed: _imageFile != null ? _upload : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BankInfo extends StatelessWidget {
  final String bank;
  final String accountNo;
  final String name;

  const _BankInfo({
    required this.bank,
    required this.accountNo,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(bank,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(accountNo,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
