import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/address.dart';

/// 收货地址服务
class AddressService {
  AddressService._internal();
  static final AddressService instance = AddressService._internal();

  static const _key = 'addresses';
  static int _nextId = 1;

  List<Address> _addresses = [];
  List<VoidCallback> _listeners = [];

  List<Address> get addresses => List.unmodifiable(_addresses);

  /// 获取默认地址
  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

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

  /// 加载地址列表
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) {
      // 首次加载时初始化模拟数据
      await _initMockData();
      return;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _addresses = list
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList();
      // 找出最大 ID
      if (_addresses.isNotEmpty) {
        _nextId = (_addresses.map((a) => a.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
      } else {
        _nextId = 1;
      }
    } catch (_) {
      _addresses = [];
      _nextId = 1;
    }
    _notifyListeners();
  }

  /// 初始化模拟数据
  Future<void> _initMockData() async {
    _addresses = [
      Address(
        id: 1,
        name: '张三',
        phone: '13812345678',
        province: '浙江省',
        city: '杭州市',
        district: '西湖区',
        detail: '文三路 123 号西湖科技大厦 A 座 1801 室',
        isDefault: true,
      ),
      Address(
        id: 2,
        name: '李四',
        phone: '13987654321',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detail: '张江高科技园区碧波路 888 号',
        isDefault: false,
      ),
      Address(
        id: 3,
        name: '王五',
        phone: '15011112222',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detail: '建国路 88 号 SOHO 现代城 B 座 1205',
        isDefault: false,
      ),
    ];
    _nextId = 4;
    await _save();
    _notifyListeners();
  }

  /// 保存地址列表
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_addresses.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  /// 添加地址
  Future<void> add(Address address) async {
    final newAddress = address.copyWith(id: _nextId++);

    // 如果是默认地址，取消其他默认
    if (newAddress.isDefault) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }

    _addresses.add(newAddress);
    await _save();
    _notifyListeners();
  }

  /// 更新地址
  Future<void> update(Address address) async {
    if (address.id == null) return;

    // 如果是默认地址，取消其他默认
    if (address.isDefault) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }

    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      _addresses[index] = address;
      await _save();
      _notifyListeners();
    }
  }

  /// 删除地址
  Future<void> remove(int id) async {
    _addresses.removeWhere((a) => a.id == id);
    await _save();
    _notifyListeners();
  }

  /// 设置默认地址
  Future<void> setDefault(int id) async {
    _addresses = _addresses.map((a) {
      return a.copyWith(isDefault: a.id == id);
    }).toList();
    await _save();
    _notifyListeners();
  }
}