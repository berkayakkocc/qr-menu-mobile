import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_service.dart';
import '../models/item.dart';

class ItemFormScreen extends StatefulWidget {
  final String categoryId;
  final String? itemId;

  const ItemFormScreen({super.key, required this.categoryId, this.itemId});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isFetchingItem = false;
  String? _error;

  bool get _isEdit => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _fetchItem();
  }

  Future<void> _fetchItem() async {
    setState(() => _isFetchingItem = true);
    try {
      final data = await ApiService.get('/items/${widget.itemId}') as Map<String, dynamic>;
      final item = Item.fromJson(data);
      _nameCtrl.text = item.name;
      _descCtrl.text = item.description ?? '';
      _priceCtrl.text = item.price.toStringAsFixed(2);
      _imageCtrl.text = item.imageUrl ?? '';
      setState(() => _isAvailable = item.isAvailable);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _isFetchingItem = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    if (price == null) {
      setState(() => _error = 'Geçerli bir fiyat girin');
      return;
    }

    final imageUrl = _imageCtrl.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'price': price,
        'image_url': imageUrl.isEmpty ? null : imageUrl,
        'is_available': _isAvailable,
      };

      if (_isEdit) {
        await ApiService.put('/items/${widget.itemId}', body);
      } else {
        await ApiService.post('/categories/${widget.categoryId}/items', body);
      }

      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingItem) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Ürünü Düzenle' : 'Ürün Ekle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ürünü Düzenle' : 'Ürün Ekle'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı *',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ürün adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                textInputAction: TextInputAction.next,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Fiyat (₺) *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Fiyat gerekli';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) return 'Geçerli bir fiyat girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Görsel URL (isteğe bağlı)',
                  prefixIcon: Icon(Icons.image_outlined),
                  hintText: 'https://example.com/image.jpg',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!Uri.tryParse(v.trim())!.hasAbsolutePath) {
                    return 'Geçerli bir URL girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                title: const Text('Ürün mevcut'),
                subtitle: const Text('Kapalıysa menüde görünmez'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
