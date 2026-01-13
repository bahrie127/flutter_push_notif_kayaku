# Training: Universal Links & App Links (Deep Link dari URL)

## PT Kayaku - Flutter Deep Linking Training
**Topik:** Klik link di Sosmed/Browser → Buka App di Halaman Tertentu

---

## Daftar Isi
1. [Konsep Deep Link dari URL](#1-konsep-deep-link-dari-url)
2. [Jenis-jenis Deep Link](#2-jenis-jenis-deep-link)
3. [Arsitektur & Flow](#3-arsitektur--flow)
4. [Setup Android App Links](#4-setup-android-app-links)
5. [Setup iOS Universal Links](#5-setup-ios-universal-links)
6. [Implementasi Flutter](#6-implementasi-flutter)
7. [Setup Domain & Server](#7-setup-domain--server)
8. [Testing](#8-testing)
9. [Contoh Kasus Nyata](#9-contoh-kasus-nyata)

---

## 1. Konsep Deep Link dari URL

### Skenario
User melihat postingan di Instagram/WhatsApp/Twitter dengan link:
```
https://kayaku.com/product/123
```

Ketika di-tap:
- **Jika app terinstall** → Buka app langsung ke halaman product 123
- **Jika app tidak terinstall** → Buka website atau Play Store

### Perbedaan dengan Push Notification Deep Link

| Aspek | Push Notification | URL Deep Link |
|-------|-------------------|---------------|
| Trigger | Server kirim notifikasi | User klik link |
| Sumber | Firebase/APNs | Sosmed, SMS, Email, QR Code |
| Data | Payload JSON | URL Path & Query |
| Kondisi | App harus terinstall | Bisa fallback ke web |

---

## 2. Jenis-jenis Deep Link

### 2.1 Custom URL Scheme (Deep Link Lama)
```
kayaku://product/123
myapp://order/456
```

**Kelebihan:**
- Mudah setup
- Tidak butuh domain

**Kekurangan:**
- Tidak aman (app lain bisa claim scheme yang sama)
- Tidak bisa fallback ke web
- Tidak jalan di semua platform

### 2.2 App Links (Android) & Universal Links (iOS)
```
https://kayaku.com/product/123
https://kayaku.com/promo/DISCOUNT50
```

**Kelebihan:**
- Aman (verified ownership via domain)
- Fallback ke web jika app tidak terinstall
- SEO friendly
- Satu link untuk semua platform

**Kekurangan:**
- Butuh domain & server setup
- Konfigurasi lebih kompleks

### 2.3 Firebase Dynamic Links (Deprecated)
```
https://kayaku.page.link/product123
```

> ⚠️ **Note:** Firebase Dynamic Links sudah deprecated per Agustus 2025. Gunakan App Links/Universal Links.

---

## 3. Arsitektur & Flow

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER KLIK LINK                                │
│         https://kayaku.com/product/123                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      OS CHECK                                    │
│  1. Apakah domain ini verified untuk app tertentu?              │
│  2. Apakah app tersebut terinstall?                             │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│    APP TERINSTALL       │     │   APP TIDAK INSTALL     │
│                         │     │                         │
│  App dibuka dengan      │     │  Buka di browser        │
│  URI data dari link     │     │  (website fallback)     │
└─────────────────────────┘     └─────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER APP                                   │
│  1. Terima URI: https://kayaku.com/product/123                  │
│  2. Parse path: /product/123                                     │
│  3. Extract: type=product, id=123                                │
│  4. Navigate ke ProductDetailScreen dengan id=123               │
└─────────────────────────────────────────────────────────────────┘
```

### Komponen yang Dibutuhkan

1. **Domain** - kayaku.com (harus HTTPS)
2. **Verification File** - Di server untuk prove ownership
3. **Android** - AndroidManifest.xml intent-filter
4. **iOS** - Associated Domains entitlement
5. **Flutter** - Package untuk handle incoming links

---

## 4. Setup Android App Links

### 4.1 Update AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

Tambahkan intent-filter di dalam `<activity>`:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    ...>

    <!-- Intent filter yang sudah ada -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- TAMBAHKAN: App Links intent-filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <!-- Domain yang akan di-handle -->
        <data
            android:scheme="https"
            android:host="kayaku.com" />
        <data
            android:scheme="https"
            android:host="www.kayaku.com" />
    </intent-filter>

    <!-- OPTIONAL: Custom URL Scheme (fallback) -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <data android:scheme="kayaku" />
    </intent-filter>

</activity>
```

### 4.2 Penjelasan Atribut

| Atribut | Fungsi |
|---------|--------|
| `android:autoVerify="true"` | Otomatis verifikasi ownership domain |
| `android:scheme="https"` | Hanya handle HTTPS links |
| `android:host="kayaku.com"` | Domain yang di-handle |

### 4.3 Path Patterns (Optional)

Untuk handle path tertentu saja:

```xml
<data
    android:scheme="https"
    android:host="kayaku.com"
    android:pathPrefix="/product" />

<data
    android:scheme="https"
    android:host="kayaku.com"
    android:pathPrefix="/promo" />
```

---

## 5. Setup iOS Universal Links

### 5.1 Update Info.plist

File: `ios/Runner/Info.plist`

Tambahkan URL Types untuk custom scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.kayaku.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kayaku</string>
        </array>
    </dict>
</array>
```

### 5.2 Enable Associated Domains

Di Xcode:
1. Buka `ios/Runner.xcworkspace`
2. Pilih **Runner** target
3. Tab **Signing & Capabilities**
4. Klik **+ Capability**
5. Pilih **Associated Domains**
6. Tambahkan:
   ```
   applinks:kayaku.com
   applinks:www.kayaku.com
   ```

### 5.3 Update Runner.entitlements

File: `ios/Runner/Runner.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:kayaku.com</string>
        <string>applinks:www.kayaku.com</string>
    </array>
</dict>
</plist>
```

---

## 6. Implementasi Flutter

### 6.1 Install Package

Tambahkan di `pubspec.yaml`:

```yaml
dependencies:
  app_links: ^6.3.3   # Untuk handle deep links
  # atau
  uni_links: ^0.5.1   # Alternatif (lebih lama tapi stabil)
```

Jalankan:
```bash
flutter pub get
```

### 6.2 Buat Deep Link Service

Buat file `lib/services/deep_link_service.dart`:

```dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callback untuk navigasi
  Function(Uri)? _onDeepLink;

  /// Initialize deep link handling
  Future<void> init({required Function(Uri) onDeepLink}) async {
    _onDeepLink = onDeepLink;

    // 1. Handle link yang membuka app dari terminated state
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Initial deep link: $initialUri');
        // Delay untuk memastikan app sudah ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _onDeepLink?.call(initialUri);
        });
      }
    } catch (e) {
      debugPrint('❌ Error getting initial link: $e');
    }

    // 2. Handle link saat app sudah running (foreground/background)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 Deep link received: $uri');
        _onDeepLink?.call(uri);
      },
      onError: (err) {
        debugPrint('❌ Deep link error: $err');
      },
    );
  }

  /// Parse URI dan return route info
  static DeepLinkRoute? parseUri(Uri uri) {
    debugPrint('📍 Parsing URI - Path: ${uri.path}, Segments: ${uri.pathSegments}');

    // Handle berbagai format URL
    // https://kayaku.com/product/123
    // https://kayaku.com/promo/DISCOUNT50
    // kayaku://product/123

    if (uri.pathSegments.isEmpty) return null;

    final type = uri.pathSegments[0];
    final id = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    final queryParams = uri.queryParameters;

    switch (type) {
      case 'product':
        return DeepLinkRoute(
          routeName: '/product-detail',
          arguments: {
            'type': 'product',
            'product_id': id,
            ...queryParams,
          },
        );

      case 'order':
        return DeepLinkRoute(
          routeName: '/order',
          arguments: {
            'type': 'order',
            'order_id': id,
            ...queryParams,
          },
        );

      case 'promo':
        return DeepLinkRoute(
          routeName: '/promo',
          arguments: {
            'type': 'promo',
            'promo_code': id,
            ...queryParams,
          },
        );

      case 'news':
        return DeepLinkRoute(
          routeName: '/news-detail',
          arguments: {
            'type': 'news',
            'news_id': id,
            ...queryParams,
          },
        );

      default:
        debugPrint('⚠️ Unknown deep link type: $type');
        return null;
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}

/// Model untuk route result
class DeepLinkRoute {
  final String routeName;
  final Map<String, dynamic> arguments;

  DeepLinkRoute({
    required this.routeName,
    required this.arguments,
  });
}
```

### 6.3 Update main.dart

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/auth_service.dart';
import 'services/deep_link_service.dart';  // TAMBAH
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/register_screen.dart';
import 'screens/product_detail_screen.dart';  // TAMBAH

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Init FCM (Push Notification)
  await FcmService().init(
    onNotificationTap: (data) {
      _handleNavigation(data);
    },
  );

  // Init Deep Link Service (URL Links)
  await DeepLinkService().init(
    onDeepLink: (uri) {
      final route = DeepLinkService.parseUri(uri);
      if (route != null) {
        _handleNavigation(route.arguments, routeName: route.routeName);
      }
    },
  );

  runApp(const MyApp());
}

/// Unified navigation handler untuk Push Notification & Deep Link
void _handleNavigation(Map<String, dynamic> data, {String? routeName}) {
  // Jika routeName sudah ditentukan (dari deep link)
  if (routeName != null) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: data);
    return;
  }

  // Fallback ke type-based routing (dari push notification)
  final type = data['type'];
  switch (type) {
    case 'order':
      navigatorKey.currentState?.pushNamed('/order', arguments: data);
      break;
    case 'promo':
      navigatorKey.currentState?.pushNamed('/promo', arguments: data);
      break;
    case 'product':
      navigatorKey.currentState?.pushNamed('/product-detail', arguments: data);
      break;
    case 'news':
      navigatorKey.currentState?.pushNamed('/news-detail', arguments: data);
      break;
    default:
      debugPrint('⚠️ Unknown navigation type: $type');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Kayaku App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/order': (context) => const OrderScreen(),
        '/promo': (context) => const PromoScreen(),
        '/product-detail': (context) => const ProductDetailScreen(),
        // Tambah routes lain sesuai kebutuhan
      },
    );
  }
}

// ... SplashScreen dan screen lainnya tetap sama
```

---

## 7. Setup Domain & Server

### 7.1 Android: assetlinks.json

Buat file di server: `https://kayaku.com/.well-known/assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.kayaku.flutter_push_notif_kayaku",
      "sha256_cert_fingerprints": [
        "XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX"
      ]
    }
  }
]
```

#### Cara Mendapatkan SHA256 Fingerprint

**Debug key:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release key:**
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-alias
```

### 7.2 iOS: apple-app-site-association

Buat file di server: `https://kayaku.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["TEAM_ID.com.kayaku.flutterPushNotifKayaku"],
        "paths": [
          "/product/*",
          "/order/*",
          "/promo/*",
          "/news/*"
        ]
      }
    ]
  }
}
```

> **Note:** Ganti `TEAM_ID` dengan Apple Developer Team ID Anda.

### 7.3 Server Configuration

File harus served dengan:
- Content-Type: `application/json`
- HTTPS (wajib)
- No redirects

**Nginx example:**
```nginx
location /.well-known/assetlinks.json {
    default_type application/json;
    alias /var/www/html/.well-known/assetlinks.json;
}

location /.well-known/apple-app-site-association {
    default_type application/json;
    alias /var/www/html/.well-known/apple-app-site-association;
}
```

**Laravel example (routes/web.php):**
```php
Route::get('/.well-known/assetlinks.json', function () {
    return response()->json([
        [
            'relation' => ['delegate_permission/common.handle_all_urls'],
            'target' => [
                'namespace' => 'android_app',
                'package_name' => 'com.kayaku.flutter_push_notif_kayaku',
                'sha256_cert_fingerprints' => [
                    'YOUR_SHA256_HERE'
                ]
            ]
        ]
    ]);
});

Route::get('/.well-known/apple-app-site-association', function () {
    return response()->json([
        'applinks' => [
            'apps' => [],
            'details' => [
                [
                    'appIDs' => ['TEAM_ID.com.kayaku.flutterPushNotifKayaku'],
                    'paths' => ['/product/*', '/order/*', '/promo/*']
                ]
            ]
        ]
    ]);
});
```

---

## 8. Testing

### 8.1 Test Android App Links

**Via ADB:**
```bash
# Test product link
adb shell am start -a android.intent.action.VIEW \
  -d "https://kayaku.com/product/123" \
  com.kayaku.flutter_push_notif_kayaku

# Test promo link
adb shell am start -a android.intent.action.VIEW \
  -d "https://kayaku.com/promo/DISCOUNT50" \
  com.kayaku.flutter_push_notif_kayaku

# Test custom scheme
adb shell am start -a android.intent.action.VIEW \
  -d "kayaku://product/123" \
  com.kayaku.flutter_push_notif_kayaku
```

**Via Notes/SMS:**
1. Kirim link ke diri sendiri via SMS atau simpan di Notes
2. Tap link tersebut
3. Pilih app saat muncul app chooser (atau langsung buka jika verified)

### 8.2 Test iOS Universal Links

**Via Notes:**
1. Buka Notes app
2. Ketik: `https://kayaku.com/product/123`
3. Long press link → pilih "Open in App"

**Via Safari:**
1. Buka Safari
2. Ketik URL dan enter
3. Jika verified, akan ada banner "Open in App"

### 8.3 Verify Domain Setup

**Android:**
```bash
# Check assetlinks.json
curl -I https://kayaku.com/.well-known/assetlinks.json

# Google's verification tool
https://developers.google.com/digital-asset-links/tools/generator
```

**iOS:**
```bash
# Check apple-app-site-association
curl -I https://kayaku.com/.well-known/apple-app-site-association

# Apple's CDN (setelah beberapa jam)
curl https://app-site-association.cdn-apple.com/a/v1/kayaku.com
```

### 8.4 Test di Sosial Media

1. **WhatsApp:** Kirim link ke chat, tap link
2. **Instagram:** Taruh link di bio atau story, tap
3. **Twitter/X:** Post dengan link, tap
4. **Email:** Kirim email dengan link, tap

---

## 9. Contoh Kasus Nyata

### 9.1 Share Product di WhatsApp

**Marketing kirim:**
```
Hai! Cek produk terbaru kami:
https://kayaku.com/product/LAPTOP-001?ref=whatsapp

Diskon 20% khusus hari ini!
```

**Flow:**
1. User tap link
2. App terbuka (jika terinstall)
3. Langsung ke halaman ProductDetailScreen
4. Data: `{product_id: "LAPTOP-001", ref: "whatsapp"}`

### 9.2 Promo Code dari Instagram

**Post Instagram:**
```
Gunakan kode promo INSTAGRAM20 untuk diskon 20%!
Link: https://kayaku.com/promo/INSTAGRAM20
```

**User tap → App buka → PromoScreen dengan kode INSTAGRAM20**

### 9.3 Order Tracking dari SMS

**SMS otomatis:**
```
Pesanan Anda #ORD-12345 sedang dikirim.
Track: https://kayaku.com/order/ORD-12345
```

**User tap → App buka → OrderScreen dengan detail tracking**

### 9.4 QR Code di Toko Fisik

**QR Code berisi:**
```
https://kayaku.com/product/SKU-789?source=store_qr&branch=jakarta
```

**Scan QR → App buka → ProductDetailScreen dengan tracking source**

---

## Ringkasan Implementasi

### Checklist Setup

**Android:**
- [ ] Update AndroidManifest.xml dengan intent-filter
- [ ] Set `android:autoVerify="true"`
- [ ] Upload assetlinks.json ke server

**iOS:**
- [ ] Add Associated Domains capability di Xcode
- [ ] Update Runner.entitlements
- [ ] Upload apple-app-site-association ke server

**Flutter:**
- [ ] Install `app_links` package
- [ ] Buat DeepLinkService
- [ ] Update main.dart dengan deep link handler
- [ ] Buat/update screens untuk handle arguments

**Server:**
- [ ] Setup /.well-known/assetlinks.json
- [ ] Setup /.well-known/apple-app-site-association
- [ ] Pastikan HTTPS dan no redirects

### URL Format yang Didukung

| URL | Route | Data |
|-----|-------|------|
| `https://kayaku.com/product/123` | /product-detail | product_id: 123 |
| `https://kayaku.com/order/ORD-456` | /order | order_id: ORD-456 |
| `https://kayaku.com/promo/CODE50` | /promo | promo_code: CODE50 |
| `kayaku://product/123` | /product-detail | product_id: 123 |

---

## Troubleshooting

| Masalah | Penyebab | Solusi |
|---------|----------|--------|
| Link buka browser, bukan app | Domain belum verified | Cek assetlinks.json/apple-app-site-association |
| App chooser muncul terus | autoVerify gagal | Pastikan SHA256 fingerprint benar |
| iOS tidak detect link | CDN belum update | Tunggu 24-48 jam setelah upload |
| Deep link tidak navigasi | Service belum init | Pastikan DeepLinkService.init() dipanggil |
| Path tidak match | Typo di pathSegments | Debug dengan print URI |

---

*Dokumentasi untuk Training PT Kayaku - Deep Linking dari URL*
