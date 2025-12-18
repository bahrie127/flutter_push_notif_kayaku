import 'package:flutter/material.dart';
import 'package:flutter_push_notif_kayaku/services/fcm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _token = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await FcmService().getToken();
    setState(() => _token = token ?? 'Token tidak ditemukan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _token,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => FcmService().subscribeToTopic('promo'),
              icon: const Icon(Icons.notifications_active),
              label: const Text('Subscribe Promo'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => FcmService().unsubscribeFromTopic('promo'),
              icon: const Icon(Icons.notifications_off),
              label: const Text('Unsubscribe Promo'),
            ),
          ],
        ),
      ),
    );
  }
}
