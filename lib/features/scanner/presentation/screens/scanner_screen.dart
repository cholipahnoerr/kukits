import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScannerBloc, ScannerState>(
      listener: (context, state) {
        if (state is ScannerSuccess) {
          context.push(RouteNames.scanResult, extra: state);
        } else if (state is ScannerNotFood) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bukan gambar makanan, coba lagi')),
          );
        } else if (state is ScannerError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Scan Makanan AI')),
        body: BlocBuilder<ScannerBloc, ScannerState>(
          builder: (context, state) {
            if (state is ScannerLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Menganalisis makanan dengan AI...'),
                  ],
                ),
              );
            }
            return _IdleView();
          },
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  Future<void> _pick(BuildContext context, ImageSource source) async {
    final xFile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (xFile == null) return;
    if (!context.mounted) return;
    context.read<ScannerBloc>().add(ScannerAnalyze(File(xFile.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_enhance_outlined,
                size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Scan Kalori dengan AI',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ambil foto makananmu, dan AI akan memperkirakan kalori serta nutrisinya secara otomatis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _pick(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Buka Kamera'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pick(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Pilih dari Galeri'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
