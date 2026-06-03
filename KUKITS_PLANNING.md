# Kukits — Perencanaan Proyek Lengkap

> Aplikasi mobile Flutter untuk penjualan kukusan terintegrasi dengan tracker nutrisi, scan kalori AI, dan meal planner.

---

## Daftar Isi

1. [Gambaran Umum](#1-gambaran-umum)
2. [Fitur Aplikasi](#2-fitur-aplikasi)
3. [Tech Stack](#3-tech-stack)
4. [Struktur Folder](#4-struktur-folder)
5. [Skema Database Firestore](#5-skema-database-firestore)
6. [Alur Pembayaran Manual](#6-alur-pembayaran-manual)
7. [Fase Pengembangan](#7-fase-pengembangan)
8. [Panduan Setup Project](#8-panduan-setup-project)
9. [Dependencies (pubspec.yaml)](#9-dependencies-pubspecyaml)
10. [Firestore Security Rules](#10-firestore-security-rules)
11. [Catatan Penting](#11-catatan-penting)

---

## 1. Gambaran Umum

**Nama Aplikasi:** Kukits  
**Platform:** Android (Flutter)  
**Backend:** Firebase (Auth, Firestore, Storage)  
**Target Pasar:** Pengguna Indonesia yang ingin hidup sehat dengan makanan kukus

### Deskripsi Singkat
Kukits adalah aplikasi mobile yang menggabungkan platform penjualan kukusan dengan ekosistem gaya hidup sehat. Pengguna dapat membeli produk kukusan, melacak nutrisi harian, memindai kalori makanan menggunakan AI, serta merencanakan jadwal makan — semuanya dalam satu aplikasi.

### Nilai Jual Utama
- Satu-satunya aplikasi yang menggabungkan **e-commerce kukusan** dengan **health tracker**
- Scan kalori makanan kukus secara instan menggunakan **AI Vision**
- Pembayaran sederhana via **transfer bank manual & COD** — cocok untuk pasar lokal
- Meal planner dengan **push notification** pengingat jadwal makan

---

## 2. Fitur Aplikasi

### Fitur Utama

#### 🛒 Toko & Penjualan
- Katalog produk kukusan (list & detail)
- Keranjang belanja
- Checkout dengan pilihan Transfer Bank atau COD
- Upload foto bukti transfer
- Tracking status pesanan real-time
- Riwayat pesanan

#### 🥗 Tracker Nutrisi Harian
- Log makanan per waktu makan (sarapan, makan siang, makan malam, snack)
- Input manual nama makanan & estimasi nutrisi
- Dashboard kalori & makro harian (kalori, protein, karbo, lemak)
- Progress bar vs target harian
- Riwayat log per tanggal

#### 📷 Scan Kalori AI
- Buka kamera / pilih dari galeri
- Kirim gambar ke Gemini Vision API
- Terima estimasi: nama makanan, kalori, protein, karbo, lemak
- Simpan langsung ke food log

#### 📅 Meal Planner & Reminder
- Buat jadwal menu makan mingguan
- Set waktu reminder per jadwal
- Push notification otomatis
- Tandai jadwal sebagai "sudah dimakan"
- Integrasi dengan tracker nutrisi

### Fitur Pendukung

#### 🔐 Autentikasi
- Register dengan email & password
- Login dengan email & password
- Login dengan Google (SSO)
- Lupa / reset password
- Logout

#### 👤 Profil Pengguna
- Edit nama, foto, nomor HP, alamat
- Set target nutrisi harian (kalori, protein, karbo, lemak)
- Riwayat pesanan
- Pengaturan notifikasi

#### 📖 Resep Kukus *(Bonus - Fase 5)*
- Daftar resep masakan kukus
- Detail resep (bahan, langkah, waktu masak, kalori)
- Tambah resep langsung ke meal plan

#### 🛠️ Admin Panel
- Dashboard ringkasan (total pesanan, produk terjual)
- Manajemen produk (tambah, edit, hapus, stok)
- Manajemen pesanan (lihat semua, konfirmasi pembayaran, update status)
- Konfirmasi bukti transfer

---

## 3. Tech Stack

### Frontend
| Teknologi | Kegunaan |
|---|---|
| Flutter 3.x | Framework utama |
| Dart | Bahasa pemrograman |
| flutter_bloc | State management |
| go_router | Navigasi & deep linking |
| dio | HTTP client |
| hive / hive_flutter | Local storage / cache |

### Backend & Cloud
| Teknologi | Kegunaan |
|---|---|
| Firebase Authentication | Login, register, Google SSO |
| Cloud Firestore | Database utama |
| Firebase Storage | Upload gambar produk & bukti transfer |
| Firebase Cloud Messaging | Push notification (opsional) |

### AI & Nutrisi
| Teknologi | Kegunaan |
|---|---|
| Google Gemini Vision API | Scan kalori dari foto makanan |
| flutter_local_notifications | Reminder jadwal makan lokal |

### Tools
| Teknologi | Kegunaan |
|---|---|
| Android Studio | IDE utama |
| Claude Code | AI coding assistant di terminal |
| Firebase Console | Manage backend |
| Postman | Test API (opsional) |

---

## 4. Struktur Folder

```
lib/
├── main.dart
├── app.dart
│
├── config/
│   ├── env.dart                    # API keys — JANGAN di-commit!
│   └── firebase_options.dart       # Auto-generated Firebase
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_sizes.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── loading_widget.dart
│   │   └── error_widget.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart         # Format harga, tanggal, dll
│   │   └── extensions.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── storage_service.dart
│   │   └── notification_service.dart
│   └── router/
│       ├── app_router.dart
│       └── route_names.dart
│
├── features/
│   │
│   ├── auth/                       # FASE 1
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_remote_datasource.dart
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart
│   │       │   └── forgot_password_screen.dart
│   │       └── bloc/
│   │           ├── auth_bloc.dart
│   │           ├── auth_event.dart
│   │           └── auth_state.dart
│   │
│   ├── shop/                       # FASE 2
│   │   ├── data/
│   │   │   ├── product_repository.dart
│   │   │   └── order_repository.dart
│   │   ├── domain/
│   │   │   ├── product_model.dart
│   │   │   ├── order_model.dart
│   │   │   └── cart_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── product_list_screen.dart
│   │       │   ├── product_detail_screen.dart
│   │       │   ├── cart_screen.dart
│   │       │   ├── checkout_screen.dart
│   │       │   ├── upload_bukti_screen.dart
│   │       │   └── order_status_screen.dart
│   │       └── bloc/
│   │           ├── shop_bloc.dart
│   │           ├── shop_event.dart
│   │           ├── shop_state.dart
│   │           ├── cart_bloc.dart
│   │           ├── cart_event.dart
│   │           └── cart_state.dart
│   │
│   ├── nutrition/                  # FASE 3
│   │   ├── data/
│   │   │   └── nutrition_repository.dart
│   │   ├── domain/
│   │   │   ├── food_log_model.dart
│   │   │   └── daily_summary_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── nutrition_dashboard_screen.dart
│   │       │   ├── add_food_screen.dart
│   │       │   └── food_history_screen.dart
│   │       └── bloc/
│   │           ├── nutrition_bloc.dart
│   │           ├── nutrition_event.dart
│   │           └── nutrition_state.dart
│   │
│   ├── scanner/                    # FASE 4 — AI
│   │   ├── data/
│   │   │   ├── ai_service.dart     # Integrasi Gemini Vision
│   │   │   └── scanner_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── scanner_screen.dart
│   │       │   └── scan_result_screen.dart
│   │       └── bloc/
│   │           ├── scanner_bloc.dart
│   │           ├── scanner_event.dart
│   │           └── scanner_state.dart
│   │
│   ├── planner/                    # FASE 3
│   │   ├── data/
│   │   │   └── planner_repository.dart
│   │   ├── domain/
│   │   │   ├── meal_plan_model.dart
│   │   │   └── reminder_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── planner_screen.dart
│   │       │   └── add_meal_screen.dart
│   │       └── bloc/
│   │           ├── planner_bloc.dart
│   │           ├── planner_event.dart
│   │           └── planner_state.dart
│   │
│   ├── profile/                    # FASE 1
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── profile_screen.dart
│   │       │   ├── edit_profile_screen.dart
│   │       │   └── order_history_screen.dart
│   │       └── bloc/
│   │           ├── profile_bloc.dart
│   │           ├── profile_event.dart
│   │           └── profile_state.dart
│   │
│   └── admin/                      # FASE 5
│       └── presentation/
│           ├── screens/
│           │   ├── admin_dashboard_screen.dart
│           │   ├── manage_products_screen.dart
│           │   ├── manage_orders_screen.dart
│           │   └── confirm_payment_screen.dart
│           └── bloc/
│               ├── admin_bloc.dart
│               ├── admin_event.dart
│               └── admin_state.dart
│
assets/
├── images/
├── icons/
└── fonts/
```

---

## 5. Skema Database Firestore

### Collection: `users`
```
/users/{userId}
├── uid            : String
├── name           : String
├── email          : String
├── photoUrl       : String?
├── role           : String        // "user" | "admin"
├── phone          : String?
├── address        : String?
├── createdAt      : Timestamp
└── nutritionTarget: Map
    ├── calories   : Number        // default: 2000
    ├── protein    : Number        // gram, default: 60
    ├── carbs      : Number        // gram, default: 250
    └── fat        : Number        // gram, default: 65
```

### Collection: `products`
```
/products/{productId}
├── name           : String
├── description    : String
├── price          : Number        // dalam rupiah
├── stock          : Number
├── imageUrls      : Array<String>
├── category       : String        // "kukusan" | "aksesori" | "bahan"
├── isActive       : Boolean
├── sold           : Number        // total unit terjual
└── createdAt      : Timestamp
```

### Collection: `orders`
```
/orders/{orderId}
├── orderId        : String        // format: "ORD-YYYYMMDD-XXX"
├── userId         : String        // ref ke users
├── items          : Array<Map>
│   ├── productId  : String
│   ├── productName: String
│   ├── quantity   : Number
│   └── price      : Number
├── totalPrice     : Number
├── deliveryMethod : String        // "transfer" | "cod"
├── deliveryAddress: String
├── status         : String
│   // menunggu_pembayaran → dibayar → diproses → dikirim → selesai
├── paymentProofUrl: String?       // URL foto bukti transfer
├── confirmedBy    : String?       // uid admin yang konfirmasi
├── confirmedAt    : Timestamp?
└── createdAt      : Timestamp
```

### Collection: `food_logs`
```
/food_logs/{logId}
├── userId         : String
├── date           : String        // format: "YYYY-MM-DD" — untuk query harian
├── mealType       : String        // "sarapan" | "makan_siang" | "makan_malam" | "snack"
├── foodName       : String
├── calories       : Number
├── protein        : Number        // gram
├── carbs          : Number        // gram
├── fat            : Number        // gram
├── portion        : String        // "1 porsi", "200g", dll
├── fromScan       : Boolean       // true jika dari AI scanner
├── imageUrl       : String?       // foto dari scan
└── createdAt      : Timestamp
```

### Collection: `meal_plans`
```
/meal_plans/{planId}
├── userId         : String
├── date           : String        // format: "YYYY-MM-DD"
├── mealType       : String        // "sarapan" | "makan_siang" | "makan_malam" | "snack"
├── menuName       : String
├── reminderTime   : String        // format: "HH:mm"
├── isReminderOn   : Boolean
├── isDone         : Boolean       // sudah dimakan atau belum
└── createdAt      : Timestamp
```

### Collection: `recipes` *(Bonus)*
```
/recipes/{recipeId}
├── title          : String
├── ingredients    : Array<String>
├── steps          : Array<String>
├── cookingTime    : Number        // menit
├── calories       : Number        // per porsi
├── imageUrl       : String
├── category       : String        // "ayam" | "ikan" | "sayur" | "dll"
└── isPublished    : Boolean
```

### Tips Query Firestore
```dart
// Log makanan hari ini
FirebaseFirestore.instance
  .collection('food_logs')
  .where('userId', isEqualTo: uid)
  .where('date', isEqualTo: '2024-06-01')
  .get();

// Semua pesanan user (terbaru)
FirebaseFirestore.instance
  .collection('orders')
  .where('userId', isEqualTo: uid)
  .orderBy('createdAt', descending: true)
  .get();

// Pesanan yang perlu dikonfirmasi admin
FirebaseFirestore.instance
  .collection('orders')
  .where('status', isEqualTo: 'dibayar')
  .get();
```

> **Catatan:** Buat composite index di Firebase Console untuk query gabungan seperti `userId + date` pada `food_logs`. Flutter akan otomatis throw error dengan link ke Firebase Console saat pertama kali dijalankan.

---

## 6. Alur Pembayaran Manual

```
User pilih produk
      ↓
Tambah ke keranjang
      ↓
Checkout → pilih metode:
  ┌─────────────┬──────────────┐
  │  Transfer   │     COD      │
  │   Bank      │              │
  └──────┬──────┴──────┬───────┘
         │              │
   Upload bukti    Status langsung
   transfer foto   "diproses"
         │
   Status: "menunggu_pembayaran"
         ↓
   Admin cek bukti transfer
         ↓
   Admin konfirmasi → Status: "dibayar"
         ↓
         Status: "diproses"
         ↓
         Status: "dikirim"
         ↓
         Status: "selesai"
```

### Status Pesanan
| Status | Deskripsi | Siapa yang Update |
|---|---|---|
| `menunggu_pembayaran` | User sudah checkout, belum bayar | Sistem otomatis |
| `dibayar` | Bukti transfer sudah diupload | User |
| `diproses` | Admin konfirmasi pembayaran | Admin |
| `dikirim` | Barang sudah dikirim | Admin |
| `selesai` | Pesanan selesai | Admin / Otomatis |

---

## 7. Fase Pengembangan

### Fase 1 — Fondasi (1–2 minggu)
- [ ] Setup project Flutter + Firebase
- [ ] Implementasi autentikasi (login, register, Google SSO)
- [ ] Bottom navigation bar
- [ ] Halaman profil & edit profil
- [ ] Routing dasar dengan go_router

### Fase 2 — Toko (2–3 minggu)
- [ ] Halaman daftar produk
- [ ] Halaman detail produk
- [ ] Fitur keranjang belanja
- [ ] Halaman checkout (Transfer / COD)
- [ ] Upload bukti transfer (Firebase Storage)
- [ ] Halaman tracking status pesanan
- [ ] Riwayat pesanan user

### Fase 3 — Nutrisi & Planner (2–3 minggu)
- [ ] Dashboard nutrisi harian
- [ ] Form input makanan manual
- [ ] Riwayat log makanan per tanggal
- [ ] Meal planner mingguan
- [ ] Setup flutter_local_notifications
- [ ] Reminder push notification jadwal makan

### Fase 4 — AI Scanner (1–2 minggu)
- [ ] Integrasi kamera (image_picker)
- [ ] Setup Gemini Vision API
- [ ] Parsing respons AI ke model nutrisi
- [ ] Halaman hasil scan
- [ ] Simpan hasil scan ke food log

### Fase 5 — Admin & Polish (1–2 minggu)
- [ ] Admin dashboard (hanya untuk role "admin")
- [ ] Manajemen produk (CRUD)
- [ ] Konfirmasi pembayaran & update status pesanan
- [ ] Halaman resep kukus
- [ ] UI/UX polish & testing
- [ ] Optimasi performa

---

## 8. Panduan Setup Project

### Langkah 1: Buat project Flutter
```bash
flutter create kukits
cd kukits
```

### Langkah 2: Setup Firebase
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Init Firebase ke project Flutter
flutterfire configure
```

### Langkah 3: Jalankan dengan Claude Code
```bash
# Di terminal Android Studio
claude
```

Contoh prompt yang efektif untuk Claude Code:
```
"Buatkan file auth_repository.dart di lib/features/auth/data/ 
dengan method login, register, loginWithGoogle, dan logout 
menggunakan Firebase Authentication"
```

```
"Buatkan user_model.dart di lib/features/auth/domain/ 
dengan field sesuai skema Firestore yang sudah ada, 
lengkap dengan fromJson, toJson, dan copyWith"
```

---

## 9. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0

  # State Management
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5

  # Navigation
  go_router: ^14.0.0

  # HTTP & AI
  dio: ^5.4.3
  http: ^1.2.1

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Image
  image_picker: ^1.1.1
  cached_network_image: ^3.3.1

  # Notifications
  flutter_local_notifications: ^17.2.1
  timezone: ^0.9.4

  # UI
  flutter_svg: ^2.0.10
  shimmer: ^3.0.0
  fl_chart: ^0.68.0        # Grafik nutrisi

  # Utils
  intl: ^0.19.0
  uuid: ^4.4.0
  google_sign_in: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  hive_generator: ^2.0.1
```

---

## 10. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isLoggedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isAdmin() {
      return isLoggedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Users — hanya bisa akses data sendiri
    match /users/{userId} {
      allow read, write: if isOwner(userId);
      allow read: if isAdmin();
    }

    // Products — semua bisa baca, hanya admin yang bisa tulis
    match /products/{productId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Orders — user hanya lihat miliknya, admin lihat semua
    match /orders/{orderId} {
      allow read: if isLoggedIn() &&
        (isOwner(resource.data.userId) || isAdmin());
      allow create: if isLoggedIn() &&
        isOwner(request.resource.data.userId);
      allow update: if isAdmin() ||
        (isOwner(resource.data.userId) &&
         request.resource.data.diff(resource.data).affectedKeys()
           .hasOnly(['paymentProofUrl', 'status']));
    }

    // Food logs — private per user
    match /food_logs/{logId} {
      allow read, write: if isLoggedIn() &&
        isOwner(resource.data.userId);
      allow create: if isLoggedIn() &&
        isOwner(request.resource.data.userId);
    }

    // Meal plans — private per user
    match /meal_plans/{planId} {
      allow read, write: if isLoggedIn() &&
        isOwner(resource.data.userId);
      allow create: if isLoggedIn() &&
        isOwner(request.resource.data.userId);
    }

    // Recipes — semua bisa baca, hanya admin yang bisa tulis
    match /recipes/{recipeId} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

---

## 11. Catatan Penting

### Keamanan
- File `env.dart` dan `google-services.json` **wajib masuk `.gitignore`**
- Gemini API key **jangan hardcode** di kode — gunakan environment variable
- Aktifkan App Check di Firebase untuk keamanan tambahan

### Gemini Vision API — Prompt yang Disarankan
```
Analisis gambar makanan ini dan berikan estimasi nutrisi dalam format JSON berikut:
{
  "foodName": "nama makanan dalam Bahasa Indonesia",
  "portion": "estimasi porsi",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0
}
Semua nilai nutrisi dalam satuan gram (kecuali kalori dalam kkal).
Jika gambar bukan makanan, kembalikan null.
```

### Composite Index yang Perlu Dibuat di Firebase Console
| Collection | Field 1 | Field 2 | Order |
|---|---|---|---|
| food_logs | userId (ASC) | date (ASC) | createdAt DESC |
| meal_plans | userId (ASC) | date (ASC) | mealType ASC |
| orders | userId (ASC) | createdAt (DESC) | — |
| orders | status (ASC) | createdAt (DESC) | — |

### Konvensi Penamaan
- File Dart: `snake_case.dart`
- Class: `PascalCase`
- Variable & method: `camelCase`
- Konstanta: `kCamelCase` atau `SCREAMING_SNAKE_CASE`
- Collection Firestore: `snake_case`

---

*Dokumen ini dibuat sebagai panduan pengembangan Kukits. Update sesuai perkembangan project.*
