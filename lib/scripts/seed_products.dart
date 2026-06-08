/// Seed script — run with:
///   flutter run -t lib/scripts/seed_products.dart
///
/// Adds all Kukits products to Firestore (skips existing by name).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../core/constants/app_colors.dart';
import '../firebase_options.dart';

// ── Product data ──────────────────────────────────────────────────

const _kukusan = [
  _Product(
    name: 'Telur',
    description: 'Telur kukus bergizi tinggi. Sumber protein lengkap yang kaya asam amino esensial, baik untuk pemulihan otot dan energi harian.',
    price: 4000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Pisang',
    description: 'Pisang kukus/segar manis alami. Sumber karbohidrat cepat dan kalium tinggi, ideal sebagai snack pre-workout atau pengisi energi.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Jagung',
    description: 'Jagung manis kukus segar. Kaya serat dan karbohidrat kompleks yang memberikan rasa kenyang lebih lama dan mendukung pencernaan sehat.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Ubi Madu',
    description: 'Ubi madu kukus dengan rasa manis alami. Indeks glikemik rendah, kaya beta-karoten dan serat, aman untuk diet defisit kalori.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Ubi Ungu',
    description: 'Ubi ungu kukus kaya antioksidan antosianin. Mendukung kesehatan jantung, meningkatkan imunitas, dan menjaga kadar gula darah stabil.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Kentang',
    description: 'Kentang kukus tanpa kulit. Sumber karbohidrat kompleks dan kalium tinggi untuk pengisian glikogen otot pasca latihan.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Ayam Rebus',
    description: 'Dada ayam rebus tanpa lemak. Protein hewani berkualitas tinggi dengan kandungan lemak minimal, sempurna untuk fase bulking dan diet lean.',
    price: 5000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Tahu',
    description: 'Tahu putih kukus segar. Sumber protein nabati yang kaya kalsium dan isoflavon, pilihan ideal untuk menu vegetarian dan vegan.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Edamame',
    description: 'Edamame kukus kedelai muda. Protein nabati lengkap dengan semua asam amino esensial, rendah kalori, dan kaya serat.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Wortel',
    description: 'Wortel rebus segar. Kaya beta-karoten, vitamin A, dan antioksidan yang mendukung kesehatan mata dan sistem imun tubuh.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Selada',
    description: 'Selada segar renyah. Rendah kalori, tinggi air dan serat, mendukung hidrasi dan pencernaan sehat dalam menu diet.',
    price: 2000,
    category: 'kukusan',
  ),
  _Product(
    name: 'Salad Sayur',
    description: 'Campuran sayuran segar: selada, wortel, dan sayuran hijau pilihan. Kaya vitamin, mineral, dan antioksidan untuk kesehatan optimal.',
    price: 3000,
    category: 'kukusan',
  ),
];

const _paket = [
  _Product(
    name: 'Muscle Builder',
    description: 'Dada ayam rebus, telur rebus (1 utuh + 1 putih telur), kentang kukus, dan edamame. Paket tinggi protein untuk fase bulking dan pemulihan otot pasca latihan beban berat.',
    price: 22000,
    category: 'paket',
  ),
  _Product(
    name: 'Sweet & Lean Diet',
    description: 'Ubi madu atau ubi ungu, dada ayam rebus, salad sayur segar, dan wortel rebus. Paket defisit kalori terkontrol dengan rasa manis alami — aman bagi gula darah untuk weight loss.',
    price: 19000,
    category: 'paket',
  ),
  _Product(
    name: 'Plant-Based Sehat',
    description: 'Tahu kukus, edamame, jagung manis, dan selada segar. Paket 100% nabati untuk vegetarian dan vegan yang mendukung detoksifikasi dan kelancaran pencernaan.',
    price: 15000,
    category: 'paket',
  ),
  _Product(
    name: 'Energy Booster',
    description: 'Pisang kukus, telur rebus, ubi ungu, dan salad sayur porsi kecil. Paket pre-workout dan post-workout untuk pengisian energi optimal dan pemulihan glikogen otot.',
    price: 18000,
    category: 'paket',
  ),
];

// ── Entry point ───────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const _SeedApp());
}

class _SeedApp extends StatelessWidget {
  const _SeedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kukits Seeder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const _LoginScreen(),
    );
  }
}

// ── Login Screen ──────────────────────────────────────────────────

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _SeedScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login gagal.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Kukits Seeder',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Login Admin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masuk dengan akun admin Firestore untuk menjalankan seed.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _Field(label: 'Email', ctrl: _emailCtrl, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _Field(label: 'Password', ctrl: _passCtrl, obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCCCC)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCC0000)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Masuk & Mulai Seed',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w600),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool obscure;
  final TextInputType keyboard;

  const _Field({
    required this.label,
    required this.ctrl,
    this.obscure = false,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            keyboardType: keyboard,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Seed Screen ───────────────────────────────────────────────────

class _SeedScreen extends StatefulWidget {
  const _SeedScreen();

  @override
  State<_SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<_SeedScreen> {
  final List<String> _log = [];
  bool _running = false;
  bool _done = false;
  int _added = 0;
  int _skipped = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _log.clear();
      _added = 0;
      _skipped = 0;
    });

    final col = FirebaseFirestore.instance.collection('products');
    final all = [..._kukusan, ..._paket];

    for (final product in all) {
      try {
        final existing = await col
            .where('name', isEqualTo: product.name)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          _addLog('⏭  Lewati: ${product.name} (sudah ada)');
          _skipped++;
          continue;
        }

        await col.add({
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'stock': 50,
          'imageUrls': [],
          'category': product.category,
          'isActive': true,
          'sold': 0,
          'createdAt': Timestamp.now(),
        });

        _addLog('✅ Ditambahkan: ${product.name} (${product.category})');
        _added++;
      } catch (e) {
        _addLog('❌ Gagal: ${product.name} — $e');
        debugPrint('SEED ERROR [${product.name}]: $e');
      }

      await Future.delayed(const Duration(milliseconds: 200));
    }

    _addLog('');
    _addLog('🎉 Selesai! $_added ditambahkan, $_skipped dilewati.');
    debugPrint('SEED DONE: $_added added, $_skipped skipped');
    setState(() {
      _running = false;
      _done = true;
    });
  }

  void _addLog(String msg) {
    debugPrint('SEED: $msg');
    setState(() => _log.add(msg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kukits Product Seeder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        '${_kukusan.length} bahan + ${_paket.length} paket = ${_kukusan.length + _paket.length} produk',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_running) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mengupload produk...',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              if (_running || _done)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.builder(
                      itemCount: _log.length,
                      itemBuilder: (_, i) => Text(
                        _log[i],
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: _log[i].startsWith('✅')
                              ? const Color(0xFF6BCB77)
                              : _log[i].startsWith('❌')
                                  ? const Color(0xFFFF6B6B)
                                  : _log[i].startsWith('⏭')
                                      ? const Color(0xFFFFD93D)
                                      : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),

              if (_done) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _done = false;
                      _log.clear();
                    }),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'Jalankan Lagi',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────

class _Product {
  final String name;
  final String description;
  final int price;
  final String category;
  const _Product({
    required this.name,
    required this.description,
    required this.price,
    required this.category,
  });
}
