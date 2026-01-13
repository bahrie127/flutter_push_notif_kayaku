// WAJIB top-level function untuk background
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_push_notif_kayaku/services/auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background: ${message.notification?.title}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // Callback untuk handle notification tap
  Function(Map<String, dynamic>)? _onNotificationTap;

  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifikasi Penting',
    description: 'Channel untuk notifikasi penting',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 Permission: ${settings.authorizationStatus}');
  }

  Future<NotificationAppLaunchDetails?> _setupLocalNotification(
    Function(Map<String, dynamic>)? onTap,
  ) async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          print('');
          print('╔══════════════════════════════════════════════════════════════');
          print('║ 📲 LOCAL NOTIFICATION TAPPED');
          print('╠══════════════════════════════════════════════════════════════');
          print('║ 📦 Payload: ${response.payload}');
          print('╚══════════════════════════════════════════════════════════════');
          try {
            // Parse JSON payload kembali ke Map
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            print('🎯 Parsed data: $data');
            // Panggil callback navigasi
            _onNotificationTap?.call(data);
          } catch (e) {
            print('❌ Error parsing payload: $e');
          }
        }
      },
    );

    // Create channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Return launch details untuk check di init()
    return await _localNotif.getNotificationAppLaunchDetails();
  }

  Future<String?> _getToken() async {
    String? token = await _fcm.getToken();
    print('🔑 FCM Token: $token');

    // Listen token refresh - KIRIM KE SERVER
    _fcm.onTokenRefresh.listen((newToken) async {
      print('🔄 Token refreshed: $newToken');
      // Kirim token baru ke server jika user sudah login
      await AuthService().refreshFcmToken(newToken);
    });

    return token;
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data), // Encode data sebagai JSON
      );
    }

    print('📬 Foreground: ${notification?.title}');
  }

  // Subscribe topic
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('✅ Subscribed to: $topic');
  }

  // Unsubscribe topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('❌ Unsubscribed from: $topic');
  }

  Future<void> init({Function(Map<String, dynamic>)? onNotificationTap}) async {
    // Simpan callback untuk digunakan di local notification handler
    _onNotificationTap = onNotificationTap;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission (Android 13+)
    await _requestPermission();

    // Setup local notification & get launch details
    final launchDetails = await _setupLocalNotification(onNotificationTap);

    // Get & print token
    await _getToken();

    // ============ CHECK APP LAUNCH FROM NOTIFICATION ============

    // 1. Check jika app dibuka dari LOCAL notification (flutter_local_notifications)
    //    Ini terjadi ketika notif masuk saat foreground, lalu app di-force close, lalu tap notif
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null) {
        print('');
        print('╔══════════════════════════════════════════════════════════════');
        print('║ 🚀 APP LAUNCHED FROM LOCAL NOTIFICATION');
        print('╠══════════════════════════════════════════════════════════════');
        print('║ 📦 Payload: $payload');
        print('╚══════════════════════════════════════════════════════════════');

        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          onNotificationTap?.call(data);
        } catch (e) {
          print('❌ Error parsing launch payload: $e');
        }
        // Return early karena sudah dihandle
        _setupListeners(onNotificationTap);
        return;
      }
    }

    // 2. Check jika app dibuka dari FCM notification (terminated state, notif dari system tray)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('');
      print('╔══════════════════════════════════════════════════════════════');
      print('║ 🚀 APP LAUNCHED FROM FCM NOTIFICATION');
      print('╠══════════════════════════════════════════════════════════════');
      print('║ 📦 Notification Data: ${initialMessage.data}');
      print('║ 📋 Title: ${initialMessage.notification?.title}');
      print('╚══════════════════════════════════════════════════════════════');

      onNotificationTap?.call(initialMessage.data);
    }

    // Setup listeners untuk foreground & background
    _setupListeners(onNotificationTap);
  }

  void _setupListeners(Function(Map<String, dynamic>)? onNotificationTap) {
    // Listener foreground
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Listener tap notification (background - app masih di memory)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('');
      print('╔══════════════════════════════════════════════════════════════');
      print('║ 📲 FCM NOTIFICATION TAPPED (Background)');
      print('╠══════════════════════════════════════════════════════════════');
      print('║ 📦 Data: ${message.data}');
      print('╚══════════════════════════════════════════════════════════════');
      onNotificationTap?.call(message.data);
    });
  }
}
