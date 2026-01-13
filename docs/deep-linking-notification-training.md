# Training: Deep Linking dari Push Notification

## PT Kayaku - Flutter Push Notification Training
**Tanggal:** 7 Januari 2026
**Topik:** Navigasi ke halaman tertentu ketika notifikasi di-tap

---

## Daftar Isi
1. [Konsep Deep Linking](#1-konsep-deep-linking)
2. [Arsitektur yang Sudah Ada](#2-arsitektur-yang-sudah-ada)
3. [Cara Kerja Deep Linking di App Ini](#3-cara-kerja-deep-linking-di-app-ini)
4. [Praktik: Menambah Route Baru](#4-praktik-menambah-route-baru)
5. [Testing dengan Firebase Console](#5-testing-dengan-firebase-console)
6. [Testing dengan cURL/Postman](#6-testing-dengan-curlpostman)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Konsep Deep Linking

### Apa itu Deep Linking?
Deep linking adalah kemampuan untuk membuka halaman **spesifik** dalam aplikasi, bukan hanya halaman utama. Dalam konteks push notification:

```
User tap notifikasi → App terbuka → Navigasi ke halaman yang relevan
```

### Jenis-jenis State Ketika Notifikasi Diterima

| State | Kondisi | Handler |
|-------|---------|---------|
| **Foreground** | App sedang aktif di layar | `FirebaseMessaging.onMessage` |
| **Background** | App di minimize/switcher | `FirebaseMessaging.onMessageOpenedApp` |
| **Terminated** | App ditutup total | `getInitialMessage()` |

### Struktur Push Notification

Push notification terdiri dari 2 bagian:

```json
{
  "notification": {
    "title": "Judul yang tampil",
    "body": "Isi pesan notifikasi"
  },
  "data": {
    "type": "order",
    "order_id": "12345",
    "custom_key": "custom_value"
  }
}
```

- **notification**: Untuk tampilan visual (title & body)
- **data**: Untuk logic deep linking (bisa berisi apapun)

---

## 2. Arsitektur yang Sudah Ada

### Global Navigator Key

```dart
// main.dart (line 10)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
```

**Fungsi:** Memungkinkan navigasi dari mana saja di app, termasuk dari service/callback.

### Route yang Tersedia

```dart
// main.dart (line 41-47)
routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const MainScreen(),
  '/order': (context) => const OrderScreen(),   // ← Deep link target
  '/promo': (context) => const PromoScreen(),   // ← Deep link target
}
```

### FCM Service Handler

```dart
// fcm_service.dart (line 133-167)
Future<void> init({Function(Map<String, dynamic>)? onNotificationTap}) async {
  _onNotificationTap = onNotificationTap;

  // ... setup code ...

  // Handle terminated state
  RemoteMessage? initialMessage = await _fcm.getInitialMessage();
  if (initialMessage != null) {
    Future.delayed(const Duration(milliseconds: 500), () {
      onNotificationTap?.call(initialMessage.data);
    });
  }

  // Handle background state
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    onNotificationTap?.call(message.data);
  });
}
```

---

## 3. Cara Kerja Deep Linking di App Ini

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     PUSH NOTIFICATION                            │
│  { notification: {...}, data: {type: "order", order_id: "123"}} │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FCM SERVICE                                 │
│  1. Terima message                                               │
│  2. Tampilkan local notification (foreground)                    │
│  3. Saat di-tap → parse payload → call onNotificationTap(data)  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MAIN.DART                                   │
│  onNotificationTap: (data) {                                     │
│    if (data['type'] == 'order') {                               │
│      navigatorKey.currentState?.pushNamed('/order', arguments); │
│    } else if (data['type'] == 'promo') {                        │
│      navigatorKey.currentState?.pushNamed('/promo', arguments); │
│    }                                                             │
│  }                                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    TARGET SCREEN                                 │
│  final data = ModalRoute.of(context)?.settings.arguments;       │
│  // Gunakan data untuk tampilkan konten yang relevan            │
└─────────────────────────────────────────────────────────────────┘
```

### Kode Handler di main.dart

```dart
// main.dart (line 17-25)
await FcmService().init(
  onNotificationTap: (data) {
    if (data['type'] == 'order') {
      navigatorKey.currentState?.pushNamed('/order', arguments: data);
    } else if (data['type'] == 'promo') {
      navigatorKey.currentState?.pushNamed('/promo', arguments: data);
    }
  },
);
```

---

## 4. Praktik: Menambah Route Baru

### Skenario: Tambah halaman "Product Detail" dari notifikasi

#### Step 1: Buat Screen Baru

Buat file `lib/screens/product_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data dari notification
    final data = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final productId = data?['product_id'] ?? 'Unknown';
    final productName = data?['product_name'] ?? 'Product';

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail: $productName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product ID: $productId',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Product Name: $productName'),
                    const SizedBox(height: 16),
                    const Text(
                      'Data dari Notifikasi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(data.toString()),
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
```

#### Step 2: Daftarkan Route di main.dart

```dart
import 'screens/product_detail_screen.dart'; // Tambah import

// Di dalam routes:
routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const MainScreen(),
  '/order': (context) => const OrderScreen(),
  '/promo': (context) => const PromoScreen(),
  '/product-detail': (context) => const ProductDetailScreen(), // BARU
}
```

#### Step 3: Tambah Handler di onNotificationTap

```dart
await FcmService().init(
  onNotificationTap: (data) {
    if (data['type'] == 'order') {
      navigatorKey.currentState?.pushNamed('/order', arguments: data);
    } else if (data['type'] == 'promo') {
      navigatorKey.currentState?.pushNamed('/promo', arguments: data);
    } else if (data['type'] == 'product') {  // BARU
      navigatorKey.currentState?.pushNamed('/product-detail', arguments: data);
    }
  },
);
```

---

## 5. Testing dengan Firebase Console

### Langkah-langkah:

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project **push-notif-kayaku**
3. Masuk ke **Messaging** di sidebar
4. Klik **Create your first campaign** atau **New campaign**
5. Pilih **Firebase Notification messages**

### Isi Form Notification:

**Notification:**
- Title: `Pesanan Anda Siap!`
- Text: `Pesanan #12345 sudah bisa diambil`

**Target:**
- Pilih app Android/iOS atau kirim ke token spesifik

**Additional options → Custom data:**

| Key | Value |
|-----|-------|
| type | order |
| order_id | 12345 |
| status | ready |

6. Klik **Review** lalu **Publish**

---

## 6. Testing dengan cURL/Postman

### Menggunakan cURL

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Promo Spesial!",
      "body": "Diskon 50% untuk semua produk"
    },
    "data": {
      "type": "promo",
      "promo_id": "PROMO2024",
      "discount": "50"
    }
  }'
```

### Menggunakan FCM v1 API (Recommended)

```bash
curl -X POST \
  'https://fcm.googleapis.com/v1/projects/push-notif-kayaku/messages:send' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "Product Baru!",
        "body": "Cek produk terbaru kami"
      },
      "data": {
        "type": "product",
        "product_id": "PROD-001",
        "product_name": "Smartphone XYZ"
      }
    }
  }'
```

### Contoh Payload untuk Berbagai Skenario

**Order Notification:**
```json
{
  "data": {
    "type": "order",
    "order_id": "ORD-12345",
    "status": "shipped",
    "tracking_number": "JNE123456"
  }
}
```

**Promo Notification:**
```json
{
  "data": {
    "type": "promo",
    "promo_id": "PROMO-2024",
    "discount_percent": "25",
    "valid_until": "2024-12-31"
  }
}
```

**Product Notification:**
```json
{
  "data": {
    "type": "product",
    "product_id": "PROD-999",
    "product_name": "Laptop Gaming",
    "price": "15000000"
  }
}
```

---

## 7. Troubleshooting

### Masalah Umum & Solusi

| Masalah | Penyebab | Solusi |
|---------|----------|--------|
| Notifikasi tidak muncul | Permission belum granted | Cek Settings > Apps > Permission |
| Tap tidak navigasi | Handler type tidak match | Pastikan `data['type']` sesuai dengan kondisi if |
| App crash saat tap | Route belum didaftarkan | Daftarkan route di `routes:` map |
| Data null di screen | Arguments tidak di-pass | Pastikan `arguments: data` saat pushNamed |
| Terminated state tidak jalan | Delay terlalu pendek | Naikkan delay di `getInitialMessage()` handler |

### Debug Tips

1. **Cek Console Log:**
   ```dart
   print('📲 Notification data: $data');
   print('🎯 Type: ${data['type']}');
   ```

2. **Verifikasi Payload:**
   Pastikan JSON payload valid dan key sesuai.

3. **Test Semua State:**
   - Foreground: App terbuka
   - Background: Minimize app, kirim notif, tap
   - Terminated: Force close app, kirim notif, tap

---

## Ringkasan

### Checklist Implementasi Deep Linking

- [ ] Buat screen tujuan dengan handling `ModalRoute.of(context)?.settings.arguments`
- [ ] Daftarkan route di `main.dart` routes map
- [ ] Tambah kondisi handler di `onNotificationTap`
- [ ] Definisikan struktur data payload yang akan digunakan
- [ ] Test di semua state (foreground, background, terminated)

### Key Points

1. **GlobalKey<NavigatorState>** memungkinkan navigasi dari luar widget tree
2. **data['type']** digunakan untuk menentukan halaman tujuan
3. **arguments** meneruskan data ke halaman tujuan
4. **ModalRoute.of(context)?.settings.arguments** untuk mengambil data di halaman tujuan

---

## Latihan Mandiri

1. Buat halaman **Chat Detail** yang bisa dibuka dari notifikasi chat
2. Tambahkan handling untuk notifikasi tipe **transaction**
3. Implementasikan halaman **News Detail** dengan parameter news_id

---

*Dokumentasi dibuat untuk training PT Kayaku*
