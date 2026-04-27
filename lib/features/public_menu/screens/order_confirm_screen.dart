import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../providers/cart_provider.dart';

class OrderConfirmScreen extends ConsumerStatefulWidget {
  final String slug;
  const OrderConfirmScreen({super.key, required this.slug});

  @override
  ConsumerState<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends ConsumerState<OrderConfirmScreen> {
  final _tableCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tableCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final body = <String, dynamic>{
        if (_tableCtrl.text.trim().isNotEmpty) 'table_no': _tableCtrl.text.trim(),
        'items': cart
            .map((i) => {'item_id': i.itemId, 'quantity': i.quantity})
            .toList(),
      };

      final data = await ApiService.post('/public/${widget.slug}/orders', body)
          as Map<String, dynamic>;

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        context.go(
          '/menu/${widget.slug}/success',
          extra: jsonEncode({
            'orderId': data['id'],
            'tableNo': data['table_no'],
          }),
        );
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold(0.0, (sum, i) => sum + i.price * i.quantity);

    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Onayla')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red[700])),
              ),
              const SizedBox(height: 16),
            ],
            // Table number field
            TextField(
              controller: _tableCtrl,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Masa Numarası (isteğe bağlı)',
                prefixIcon: Icon(Icons.table_restaurant),
                hintText: '1, 2A, Balkon...',
              ),
            ),
            const SizedBox(height: 24),
            // Order summary
            Text(
              'Sipariş Özeti',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...cart.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                              fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.name)),
                    Text(
                      '₺${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Toplam',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '₺${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB)),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Onayla ve Sipariş Ver',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
