import 'package:flutter/material.dart';

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
