// Dummy screens
import 'package:flutter/material.dart';

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
