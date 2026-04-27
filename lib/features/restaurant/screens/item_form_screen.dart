import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isFetchingItem = false;
  bool _isUploadingImage = false;
  String? _error;
  String? _imageUrl;
  Uint8List? _imagePreviewBytes;

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
      setState(() {
        _isAvailable = item.isAvailable;
        _imageUrl = item.imageUrl;
      });
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();

    setState(() {
      _isUploadingImage = true;
      _imagePreviewBytes = bytes;
      _error = null;
    });

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'items/$fileName';

      await Supabase.instance.client.storage
          .from('item-images')
          .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('item-images')
          .getPublicUrl(path);

      setState(() => _imageUrl = publicUrl);
    } catch (e) {
      setState(() {
        _error = 'Görsel yüklenemedi: $e';
        _imagePreviewBytes = null;
      });
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _removeImage() => setState(() {
        _imageUrl = null;
        _imagePreviewBytes = null;
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    if (price == null) {
      setState(() => _error = 'Geçerli bir fiyat girin');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'price': price,
        'image_url': _imageUrl,
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
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
              // Image picker
              _ImagePickerCard(
                imageUrl: _imageUrl,
                previewBytes: _imagePreviewBytes,
                isUploading: _isUploadingImage,
                onPick: _pickImage,
                onRemove: _removeImage,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı *',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ürün adı gerekli' : null,
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
                textInputAction: TextInputAction.done,
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

class _ImagePickerCard extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? previewBytes;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerCard({
    required this.imageUrl,
    required this.previewBytes,
    required this.isUploading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = previewBytes != null || imageUrl != null;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: previewBytes != null
                      ? Image.memory(previewBytes!, fit: BoxFit.cover)
                      : Image.network(imageUrl!, fit: BoxFit.cover),
                ),
                if (isUploading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: isUploading ? null : onPick,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Görsel Ekle', style: TextStyle(color: Colors.grey[600])),
                  Text('Galeriden seç', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
    );
  }
}
