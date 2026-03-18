import 'package:flutter/material.dart';

import '../models/banner.dart' as banner_model;
import '../services/api_service.dart';

class BannerManagePage extends StatefulWidget {
  const BannerManagePage({super.key});

  @override
  State<BannerManagePage> createState() => _BannerManagePageState();
}

class _BannerManagePageState extends State<BannerManagePage> {
  late Future<List<banner_model.Banner>> _futureBanners;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  void _loadBanners() {
    setState(() {
      _futureBanners = ApiService.instance.fetchAllBanners();
    });
  }

  Future<void> _deleteBanner(banner_model.Banner banner) async {
    if (banner.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${banner.title}」吗？'),
        actions: [
          TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false)),
          TextButton(
              child: const Text('删除'),
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.instance.deleteBanner(banner.id!);
      _loadBanners();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  void _openAdd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BannerEditPage()),
    );
    if (result == true && mounted) _loadBanners();
  }

  void _openEdit(banner_model.Banner banner) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BannerEditPage(banner: banner)),
    );
    if (result == true && mounted) _loadBanners();
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF1a1a2e);
    }
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1a1a2e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banner管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadBanners(),
        child: FutureBuilder<List<banner_model.Banner>>(
          future: _futureBanners,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('加载失败: ${snapshot.error}'));
            }
            final banners = snapshot.data ?? [];
            if (banners.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(
                      height: 200,
                      child: Center(child: Text('暂无Banner'))),
                ],
              );
            }
            return ListView.separated(
              itemCount: banners.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final b = banners[index];
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(b.backgroundColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${b.sortOrder}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${b.subtitle ?? ""}  |  ${b.active ? "已启用" : "已禁用"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _openEdit(b),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error),
                        onPressed: () => _deleteBanner(b),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class BannerEditPage extends StatefulWidget {
  final banner_model.Banner? banner;

  const BannerEditPage({super.key, this.banner});

  @override
  State<BannerEditPage> createState() => _BannerEditPageState();
}

class _BannerEditPageState extends State<BannerEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _imageUrlController;
  late TextEditingController _backgroundColorController;
  late TextEditingController _linkUrlController;
  late TextEditingController _sortOrderController;
  bool _active = true;

  bool get _isEdit => widget.banner != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _subtitleController = TextEditingController(text: widget.banner?.subtitle ?? '');
    _imageUrlController = TextEditingController(text: widget.banner?.imageUrl ?? '');
    _backgroundColorController = TextEditingController(text: widget.banner?.backgroundColor ?? '#1a1a2e');
    _linkUrlController = TextEditingController(text: widget.banner?.linkUrl ?? '');
    _sortOrderController = TextEditingController(text: (widget.banner?.sortOrder ?? 0).toString());
    _active = widget.banner?.active ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _backgroundColorController.dispose();
    _linkUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final banner = banner_model.Banner(
      id: widget.banner?.id,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      backgroundColor: _backgroundColorController.text.trim(),
      linkUrl: _linkUrlController.text.trim().isEmpty ? null : _linkUrlController.text.trim(),
      sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
      active: _active,
    );

    try {
      if (_isEdit) {
        await ApiService.instance.updateBanner(banner);
      } else {
        await ApiService.instance.createBanner(banner);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑Banner' : '新增Banner'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题 *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? '请输入标题' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: '副标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: '图片URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _backgroundColorController,
              decoration: const InputDecoration(
                labelText: '背景颜色 (如: #1a1a2e)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkUrlController,
              decoration: const InputDecoration(
                labelText: '跳转链接',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sortOrderController,
              decoration: const InputDecoration(
                labelText: '排序 (数字越小越靠前)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
    );
  }
}