import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/order_repository.dart';
import '../../domain/order_model.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<OrderModel>(
        stream: OrderRepository().watchOrder(orderId),
        builder: (context, snapshot) {
          final order = snapshot.data;
          return Column(
            children: [
              _TopBar(order: order),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  order == null)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (order == null)
                const Expanded(child: _NotFound())
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _StatusHero(order: order),
                      const SizedBox(height: 14),
                      _Timeline(
                          status: order.status,
                          isCod: order.deliveryMethod == 'cod'),
                      const SizedBox(height: 14),
                      if (order.status == 'menunggu_pembayaran' &&
                          order.deliveryMethod == 'transfer') ...[
                        _PaymentUploadCard(docId: orderId),
                        const SizedBox(height: 14),
                      ],
                      _OrderDetailCard(order: order),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final OrderModel? order;
  const _TopBar({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Pesanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (order != null)
                      Text(
                        order!.orderId,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status Hero ───────────────────────────────────────────────────
class _StatusHero extends StatelessWidget {
  final OrderModel order;
  const _StatusHero({required this.order});

  Color get _color => switch (order.status) {
        'menunggu_pembayaran' => const Color(0xFFE67E22),
        'dibayar' => const Color(0xFF3498DB),
        'diproses' => AppColors.primary,
        'dikirim' => const Color(0xFF9B59B6),
        'selesai' => AppColors.primary,
        _ => AppColors.textSecondary,
      };

  IconData get _icon => switch (order.status) {
        'menunggu_pembayaran' => Icons.hourglass_empty_rounded,
        'dibayar' => Icons.payment_rounded,
        'diproses' => Icons.inventory_2_outlined,
        'dikirim' => Icons.local_shipping_outlined,
        'selesai' => Icons.check_circle_outline_rounded,
        _ => Icons.help_outline_rounded,
      };

  String get _subtitle => switch (order.status) {
        'menunggu_pembayaran' =>
          'Silakan lakukan pembayaran untuk melanjutkan',
        'dibayar' => 'Pembayaran sedang diverifikasi admin',
        'diproses' => 'Pesananmu sedang dikemas',
        'dikirim' => 'Pesananmu sedang dalam perjalanan',
        'selesai' => 'Pesananmu telah diterima, terima kasih!',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x082D3436), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Icon circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border:
                  Border.all(color: _color.withValues(alpha: 0.25), width: 2),
            ),
            child: Icon(_icon, size: 36, color: _color),
          ),
          const SizedBox(height: 16),
          Text(
            order.statusLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  order.orderId,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────
class _Timeline extends StatelessWidget {
  final String status;
  final bool isCod;
  const _Timeline({required this.status, required this.isCod});

  static const _transferSteps = [
    ('menunggu_pembayaran', 'Menunggu Pembayaran',
        Icons.hourglass_empty_rounded),
    ('dibayar', 'Pembayaran Dikonfirmasi', Icons.payment_rounded),
    ('diproses', 'Pesanan Diproses', Icons.inventory_2_outlined),
    ('dikirim', 'Pesanan Dikirim', Icons.local_shipping_outlined),
    ('selesai', 'Pesanan Selesai', Icons.check_circle_outline_rounded),
  ];

  static const _codSteps = [
    ('diproses', 'Pesanan Diproses', Icons.inventory_2_outlined),
    ('dikirim', 'Pesanan Dikirim', Icons.local_shipping_outlined),
    ('selesai', 'Pesanan Selesai', Icons.check_circle_outline_rounded),
  ];

  List<(String, String, IconData)> get _steps =>
      isCod ? _codSteps : _transferSteps;

  int get _currentIndex => _steps.indexWhere((s) => s.$1 == status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x082D3436), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Perjalanan Pesanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._steps.asMap().entries.map((entry) {
            final i = entry.key;
            final (_, label, icon) = entry.value;
            final isDone = i <= _currentIndex;
            final isCurrent = i == _currentIndex;
            final isLast = i == _steps.length - 1;
            return _TimelineRow(
              label: label,
              icon: icon,
              isDone: isDone,
              isCurrent: isCurrent,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineRow({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor =
        isDone ? AppColors.primary : AppColors.divider;
    final labelColor =
        isCurrent ? AppColors.primaryDark : AppColors.textSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + connector column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isDone ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor,
                      width: isCurrent ? 2 : 1.5,
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : icon,
                    size: 15,
                    color: isDone ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Status saat ini',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Upload Card ───────────────────────────────────────────
class _PaymentUploadCard extends StatefulWidget {
  final String docId;
  const _PaymentUploadCard({required this.docId});

  @override
  State<_PaymentUploadCard> createState() => _PaymentUploadCardState();
}

class _PaymentUploadCardState extends State<_PaymentUploadCard> {
  bool _uploading = false;
  bool _uploaded = false;

  Future<void> _upload() async {
    final xFile =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;

    setState(() => _uploading = true);
    try {
      await OrderRepository()
          .uploadPaymentProof(widget.docId, File(xFile.path));
      if (mounted) setState(() => _uploaded = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uploaded) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bukti dikirim!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    'Admin akan memverifikasi pembayaranmu',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_rounded,
                    size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upload Bukti Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Kirim bukti transfer agar pesananmu segera diproses oleh admin.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _uploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(
                _uploading ? 'Mengupload...' : 'Pilih dari Galeri',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Detail Card ─────────────────────────────────────────────
class _OrderDetailCard extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailCard({required this.order});

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x082D3436), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                width: 8,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Detail Pesanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Items
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.quantity}× Rp ${_fmt(item.price)}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Rp ${_fmt(item.subtotal)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20),
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                order.formattedTotal,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 0),
          const SizedBox(height: 14),
          // Delivery info
          _InfoRow(
            icon: Icons.payment_outlined,
            label: 'Metode',
            value: order.deliveryMethod == 'transfer'
                ? 'Transfer Bank'
                : 'COD',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: order.deliveryAddress,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.primaryDark),
          ),
        ),
      ],
    );
  }
}

// ── Not Found ─────────────────────────────────────────────────────
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Pesanan tidak ditemukan',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
