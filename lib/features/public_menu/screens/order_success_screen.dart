import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String slug;
  final String? extraJson;

  const OrderSuccessScreen({super.key, required this.slug, this.extraJson});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> extra = {};
    try {
      if (extraJson != null) extra = jsonDecode(extraJson!) as Map<String, dynamic>;
    } catch (_) {}

    final orderId = extra['orderId'] as String?;
    final tableNo = extra['tableNo'] as String?;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 64, color: Colors.green[600]),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Siparişiniz Alındı!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Siparişiniz mutfağa iletildi.\nHazır olduğunda size servis edilecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                if (tableNo != null) ...[
                  const SizedBox(height: 16),
                  _InfoChip(label: 'Masa', value: tableNo),
                ],
                if (orderId != null) ...[
                  const SizedBox(height: 8),
                  _InfoChip(
                    label: 'Sipariş No',
                    value: orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId,
                  ),
                ],
                const SizedBox(height: 40),
                FilledButton.tonal(
                  onPressed: () => context.go('/menu/$slug'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('Menüye Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.grey),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      ),
    );
  }
}
