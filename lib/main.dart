import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/register_screen.dart';
import 'screens/product_detail_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Pending notification data (untuk terminated state)
Map<String, dynamic>? _pendingNotificationData;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Init FCM
  await FcmService().init(
    onNotificationTap: (data) {
      _handleNotificationTap(data);
    },
  );

  runApp(const MyApp());
}

/// Handle notification tap navigation
void _handleNotificationTap(Map<String, dynamic> data) {
  debugPrint('');
  debugPrint('╔══════════════════════════════════════════════════════════════');
  debugPrint('║ 🔔 NOTIFICATION TAP HANDLER');
  debugPrint('╠══════════════════════════════════════════════════════════════');
  debugPrint('║ 📦 Data: $data');
  debugPrint('║ 📋 Type: ${data['type']}');
  debugPrint('║ 🧭 Navigator ready: ${navigatorKey.currentState != null}');
  debugPrint('╚══════════════════════════════════════════════════════════════');

  // Cek apakah navigator sudah ready
  if (navigatorKey.currentState == null) {
    debugPrint('⏳ Navigator belum ready, menyimpan data untuk nanti...');
    _pendingNotificationData = data;
    return;
  }

  _navigateToScreen(data);
}

/// Navigate ke screen berdasarkan type
void _navigateToScreen(Map<String, dynamic> data) {
  final type = data['type'];

  debugPrint('🚀 Navigating to: $type');

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
    default:
      debugPrint('⚠️ Unknown notification type: $type');
  }
}

/// Process pending notification (dipanggil setelah app ready)
void processPendingNotification() {
  if (_pendingNotificationData != null) {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 📬 PROCESSING PENDING NOTIFICATION');
    debugPrint('║ 📦 Data: $_pendingNotificationData');
    debugPrint('╚══════════════════════════════════════════════════════════════');

    final data = _pendingNotificationData!;
    _pendingNotificationData = null; // Clear setelah diproses
    _navigateToScreen(data);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Push Notification Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
      // Gunakan onGenerateRoute untuk handle deep link + normal routes
      onGenerateRoute: (settings) {
        debugPrint('');
        debugPrint('╔══════════════════════════════════════════════════════════════');
        debugPrint('║ 🔗 ROUTE GENERATED');
        debugPrint('║ 📍 Name: ${settings.name}');
        debugPrint('║ 📦 Arguments: ${settings.arguments}');
        debugPrint('╚══════════════════════════════════════════════════════════════');

        // Parse URI dari route name (untuk deep link)
        final uri = Uri.parse(settings.name ?? '');

        // === DEEP LINK ROUTES ===
        // Format: kayaku://product/123 atau https://kayaku.com/product/123

        // /product/:id
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'product') {
          final productId = uri.pathSegments[1];
          debugPrint('🎯 Deep Link: Product ID = $productId');
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ProductDetailScreen(),
          );
        }

        // /order/:id
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'order') {
          final orderId = uri.pathSegments[1];
          debugPrint('🎯 Deep Link: Order ID = $orderId');
          return MaterialPageRoute(
            settings: RouteSettings(
              name: settings.name,
              arguments: {'order_id': orderId, ...uri.queryParameters},
            ),
            builder: (_) => const OrderScreen(),
          );
        }

        // /promo/:code atau /promo?code=XXX
        if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'promo') {
          final promoCode = uri.pathSegments.length > 1
              ? uri.pathSegments[1]
              : uri.queryParameters['code'];
          debugPrint('🎯 Deep Link: Promo Code = $promoCode');
          return MaterialPageRoute(
            settings: RouteSettings(
              name: settings.name,
              arguments: {'promo_code': promoCode, ...uri.queryParameters},
            ),
            builder: (_) => const PromoScreen(),
          );
        }

        // === NORMAL ROUTES ===
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const LoginScreen(),
            );
          case '/register':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const RegisterScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const MainScreen(),
            );
          case '/order':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const OrderScreen(),
            );
          case '/promo':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const PromoScreen(),
            );
          case '/product-detail':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ProductDetailScreen(),
            );
          default:
            // Route tidak ditemukan
            debugPrint('⚠️ Unknown route: ${settings.name}');
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SplashScreen(),
            );
        }
      },
    );
  }
}

// Splash screen untuk check login status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1)); // splash delay

    final isLoggedIn = await AuthService().checkLoginStatus();

    if (mounted) {
      // Navigate ke home/login dulu
      Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/login');

      // Setelah navigation selesai, process pending notification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        processPendingNotification();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active, size: 80, color: Colors.blue),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Dummy screens
class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)?.settings.arguments;
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: Center(child: Text('Order Data: $data')),
    );
  }
}

class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promo')),
      body: const Center(child: Text('Halaman Promo')),
    );
  }
}
