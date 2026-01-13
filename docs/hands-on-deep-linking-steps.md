# Hands-On: Step-by-Step Deep Linking dari Notifikasi

## Training PT Kayaku - Sesi Praktik

---

## Persiapan

### Yang Dibutuhkan:
- Android device/emulator dengan app terinstall
- FCM Token dari device (copy dari HomeScreen)
- Akses ke Firebase Console atau Postman
- Code editor (VS Code/Android Studio)

---

## STEP 1: Pahami Kode yang Sudah Ada

### 1.1 Buka file `lib/main.dart`

Perhatikan bagian ini:

```dart
// Line 10 - Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Line 17-25 - Handler notifikasi
await FcmService().init(
  onNotificationTap: (data) {
    if (data['type'] == 'order') {
      navigatorKey.currentState?.pushNamed('/order', arguments: data);
    } else if (data['type'] == 'promo') {
      navigatorKey.currentState?.pushNamed('/promo', arguments: data);
    }
  },
);

// Line 41-47 - Daftar routes
routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const MainScreen(),
  '/order': (context) => const OrderScreen(),
  '/promo': (context) => const PromoScreen(),
}
```

### 1.2 Buka file `lib/services/fcm_service.dart`

Perhatikan 3 handler berbeda:

```dart
// Line 149-157 - Terminated state
RemoteMessage? initialMessage = await _fcm.getInitialMessage();
if (initialMessage != null) {
  Future.delayed(const Duration(milliseconds: 500), () {
    onNotificationTap?.call(initialMessage.data);
  });
}

// Line 160 - Foreground
FirebaseMessaging.onMessage.listen(_showForegroundNotification);

// Line 163-166 - Background
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  onNotificationTap?.call(message.data);
});
```

---

## STEP 2: Test Notifikasi Order yang Sudah Ada

### 2.1 Dapatkan FCM Token

1. Buka app di device
2. Login
3. Di HomeScreen, tap tombol **Copy** di bagian FCM Token
4. Simpan token ini

### 2.2 Kirim Notifikasi via Firebase Console

1. Buka https://console.firebase.google.com
2. Pilih project `push-notif-kayaku`
3. Klik **Messaging** di sidebar kiri
4. Klik **Create your first campaign** → **Firebase Notification messages**

**Isi form:**
- Notification title: `Pesanan Anda Dikirim!`
- Notification text: `Order #12345 sedang dalam perjalanan`

5. Klik **Next** → **Target**
6. Pilih **Single device** dan paste FCM Token

7. Klik **Next** → **Scheduling** → **Now**

8. Expand **Additional options** → **Custom data**

   Tambahkan:
   | Key | Value |
   |-----|-------|
   | type | order |
   | order_id | 12345 |

9. Klik **Review** → **Publish**

### 2.3 Verifikasi

- Tap notifikasi
- App harus membuka halaman Order
- Di halaman Order, lihat data yang ditampilkan

---

## STEP 3: Buat Halaman Baru - Product Detail

### 3.1 Buat File Screen Baru

Buat file `lib/screens/product_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data dari notification arguments
    final data = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.shopping_bag, size: 60, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      data?['product_name'] ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Product ID', data?['product_id'] ?? '-'),
                    const Divider(),
                    _buildInfoRow('Harga', 'Rp ${data?['price'] ?? '0'}'),
                    const Divider(),
                    _buildInfoRow('Kategori', data?['category'] ?? '-'),
                    const Divider(),
                    _buildInfoRow('Stok', data?['stock'] ?? '-'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Raw Data Card (untuk debug)
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Raw Notification Data:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data?.toString() ?? 'No data',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produk ditambahkan ke keranjang!')),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Tambah ke Keranjang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

### 3.2 Update main.dart - Import Screen

Tambahkan import di bagian atas file:

```dart
import 'screens/product_detail_screen.dart';
```

### 3.3 Update main.dart - Daftarkan Route

Tambahkan route baru di map routes:

```dart
routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const MainScreen(),
  '/order': (context) => const OrderScreen(),
  '/promo': (context) => const PromoScreen(),
  '/product-detail': (context) => const ProductDetailScreen(), // TAMBAH INI
}
```

### 3.4 Update main.dart - Tambah Handler

Tambahkan kondisi baru di onNotificationTap:

```dart
await FcmService().init(
  onNotificationTap: (data) {
    if (data['type'] == 'order') {
      navigatorKey.currentState?.pushNamed('/order', arguments: data);
    } else if (data['type'] == 'promo') {
      navigatorKey.currentState?.pushNamed('/promo', arguments: data);
    } else if (data['type'] == 'product') {  // TAMBAH INI
      navigatorKey.currentState?.pushNamed('/product-detail', arguments: data);
    }
  },
);
```

### 3.5 Hot Restart App

```bash
# Di terminal, tekan 'R' (capital R) untuk hot restart
# Atau jalankan ulang: flutter run
```

---

## STEP 4: Test Deep Link Product

### 4.1 Kirim Notifikasi Product

Di Firebase Console, buat campaign baru dengan:

**Notification:**
- Title: `Produk Baru Tersedia!`
- Text: `Smartphone XYZ dengan harga spesial`

**Custom data:**
| Key | Value |
|-----|-------|
| type | product |
| product_id | PROD-001 |
| product_name | Smartphone XYZ |
| price | 5000000 |
| category | Electronics |
| stock | 50 |

### 4.2 Test di Berbagai State

**Test 1: Foreground**
1. Buka app, tetap di home
2. Kirim notifikasi
3. Tap notifikasi yang muncul
4. Verify: Masuk ke halaman Product Detail

**Test 2: Background**
1. Buka app, lalu minimize (home button)
2. Kirim notifikasi
3. Tap notifikasi dari notification tray
4. Verify: App terbuka langsung ke Product Detail

**Test 3: Terminated**
1. Force close app (swipe dari recent apps)
2. Kirim notifikasi
3. Tap notifikasi
4. Verify: App mulai dan langsung ke Product Detail

---

## STEP 5: Tambah Halaman News (Latihan Mandiri)

### Tugas:
Buat halaman News Detail yang bisa dibuka dari notifikasi.

### Requirements:
1. Buat `lib/screens/news_detail_screen.dart`
2. Route: `/news-detail`
3. Type: `news`
4. Data yang diharapkan:
   - news_id
   - title
   - content
   - author
   - published_date

### Template Payload untuk Test:
```json
{
  "type": "news",
  "news_id": "NEWS-001",
  "title": "Breaking News!",
  "content": "Isi berita...",
  "author": "Admin",
  "published_date": "2024-01-07"
}
```

---

## STEP 6: Implementasi dengan URL Deep Link (Advanced)

### 6.1 Konsep URL-based Deep Link

Selain menggunakan `data['type']`, kita bisa menggunakan URL:

```json
{
  "data": {
    "link": "kayaku://product/123",
    "title": "Product Title"
  }
}
```

### 6.2 Update Handler

```dart
onNotificationTap: (data) {
  // Check URL-based deep link
  if (data['link'] != null) {
    final uri = Uri.parse(data['link']);

    if (uri.pathSegments.isNotEmpty) {
      switch (uri.pathSegments[0]) {
        case 'product':
          final productId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
          navigatorKey.currentState?.pushNamed('/product-detail', arguments: {
            ...data,
            'product_id': productId,
          });
          break;
        case 'order':
          navigatorKey.currentState?.pushNamed('/order', arguments: data);
          break;
        case 'promo':
          navigatorKey.currentState?.pushNamed('/promo', arguments: data);
          break;
      }
    }
    return;
  }

  // Fallback ke type-based
  if (data['type'] == 'order') {
    navigatorKey.currentState?.pushNamed('/order', arguments: data);
  } else if (data['type'] == 'promo') {
    navigatorKey.currentState?.pushNamed('/promo', arguments: data);
  } else if (data['type'] == 'product') {
    navigatorKey.currentState?.pushNamed('/product-detail', arguments: data);
  }
}
```

---

## Checklist Training

- [ ] Memahami 3 state notifikasi (foreground, background, terminated)
- [ ] Memahami struktur payload notification vs data
- [ ] Berhasil test notifikasi Order yang sudah ada
- [ ] Berhasil membuat halaman Product Detail baru
- [ ] Berhasil mendaftarkan route baru
- [ ] Berhasil menambah handler baru
- [ ] Berhasil test di semua state
- [ ] (Bonus) Berhasil membuat halaman News sendiri

---

## Referensi File

| File | Fungsi |
|------|--------|
| `lib/main.dart` | Entry point, routes, handler |
| `lib/services/fcm_service.dart` | FCM setup & listeners |
| `lib/screens/product_detail_screen.dart` | Screen baru (dibuat di training) |

---

*Happy Coding!*
