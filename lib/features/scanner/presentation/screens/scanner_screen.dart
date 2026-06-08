import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
            const SnackBar(content: Text('Bukan gambar makanan, coba lagi')),
          );
        } else if (state is ScannerError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: BlocBuilder<ScannerBloc, ScannerState>(
          builder: (context, state) {
            if (state is ScannerLoading) return const _LoadingView();
            return const _IdleView();
          },
        ),
      ),
    );
  }
}

// ── Idle View ─────────────────────────────────────────────────────
class _IdleView extends StatelessWidget {
  const _IdleView();

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
    return Column(
      children: [
        // Top: viewfinder area
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              // Background pattern
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryDark, Color(0xFF344E3A)],
                  ),
                ),
              ),
              // Safe area top padding
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Scan Makanan AI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.accent),
                            const SizedBox(width: 5),
                            Text(
                              'AI Powered',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Center: scan frame
              Center(child: _ScanFrame()),
            ],
          ),
        ),
        // Bottom: action panel
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto makananmu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'AI akan memperkirakan kalori & nutrisi\ndari foto makananmu secara otomatis.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.camera_alt_rounded,
                          label: 'Kamera',
                          sublabel: 'Foto langsung',
                          color: AppColors.primary,
                          onTap: () => _pick(context, ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.photo_library_rounded,
                          label: 'Galeri',
                          sublabel: 'Pilih foto',
                          color: AppColors.accent,
                          onTap: () => _pick(context, ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _TipRow(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        children: [
          // Dim ring
          Center(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Corner brackets
          Positioned(top: 0, left: 0, child: _Corner(rotate: 0)),
          Positioned(top: 0, right: 0, child: _Corner(rotate: 1)),
          Positioned(bottom: 0, right: 0, child: _Corner(rotate: 2)),
          Positioned(bottom: 0, left: 0, child: _Corner(rotate: 3)),
          // Center icon
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final int rotate; // 0=TL, 1=TR, 2=BR, 3=BL
  const _Corner({required this.rotate});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate * 3.14159 / 2,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              sublabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hasil terbaik: foto terang, makanan terlihat jelas, hindari sudut jauh.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading View ──────────────────────────────────────────────────
class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, Color(0xFF344E3A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Transform.scale(
                scale: _pulse.value,
                child: child,
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Container(
                  margin: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Menganalisis makanan...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI sedang membaca kandungan nutrisi',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
