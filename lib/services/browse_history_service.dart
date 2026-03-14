import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// 浏览记录服务
/// 使用本地存储管理用户的商品浏览历史
class BrowseHistoryService {
  BrowseHistoryService._internal();
  static final BrowseHistoryService instance = BrowseHistoryService._internal();

  static const _key = 'browse_history';
  static const _maxCount = 50; // 最多保存50条记录

  List<Product> _history = [];
  List<VoidCallback> _listeners = [];

  List<Product> get history => List.unmodifiable(_history);

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 加载浏览历史
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) {
      _history = [];
      return;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _history = list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _history = [];
    }
    _notifyListeners();
  }

  /// 保存浏览历史
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_history.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  /// 添加浏览记录
  /// 将商品添加到历史列表的最前面，已存在的会移动到最前
  Future<void> add(Product product) async {
    if (product.id == null) return;

    // 移除已存在的相同商品
    _history.removeWhere((p) => p.id == product.id);

    // 添加到最前面
    _history.insert(0, product);

    // 限制最大数量
    if (_history.length > _maxCount) {
      _history = _history.sublist(0, _maxCount);
    }

    await _save();
    _notifyListeners();
  }

  /// 删除单条记录
  Future<void> remove(int productId) async {
    _history.removeWhere((p) => p.id == productId);
    await _save();
    _notifyListeners();
  }

  /// 清空所有浏览记录
  Future<void> clear() async {
    _history = [];
    await _save();
    _notifyListeners();
  }
}