import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class ProductEditPage extends StatefulWidget {
  final Product? product;
  const ProductEditPage({super.key, this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _originalPriceCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _ratingCtrl;
  late final TextEditingController _salesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _originalPriceCtrl = TextEditingController(
        text: p?.originalPrice != null ? p!.originalPrice.toString() : '');
    _imageUrlCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _ratingCtrl =
        TextEditingController(text: p != null ? p.rating.toString() : '4.5');
    _salesCtrl = TextEditingController(
        text: p != null ? p.salesCount.toString() : '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _imageUrlCtrl.dispose();
    _categoryCtrl.dispose();
    _ratingCtrl.dispose();
    _salesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      originalPrice: _originalPriceCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_originalPriceCtrl.text),
      imageUrl: _imageUrlCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      rating: double.tryParse(_ratingCtrl.text) ?? 4.5,
      salesCount: int.tryParse(_salesCtrl.text) ?? 0,
    );

    setState(() => _saving = true);
    try {
      if (product.id == null) {
        await ApiService.instance.createProduct(product);
      } else {
        await ApiService.instance.updateProduct(product);
      }
      if (!mounted) return;
      Navigator.of(context).pop<bool>(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑商品' : '新增商品')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field('商品名称', _nameCtrl, required: true),
              _field('分类', _categoryCtrl, required: true),
              _field('价格', _priceCtrl,
                  required: true, keyboard: TextInputType.number),
              _field('原价', _originalPriceCtrl,
                  keyboard: TextInputType.number),
              _field('图片URL', _imageUrlCtrl),
              _field('描述', _descCtrl, maxLines: 3),
              _field('评分', _ratingCtrl, keyboard: TextInputType.number),
              _field('销量', _salesCtrl,
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : Text(isEdit ? '保存' : '创建',
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        inputFormatters: formatters,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '请输入$label' : null
            : null,
      ),
    );
  }
}
