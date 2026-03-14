import 'package:flutter/material.dart';

import '../models/address.dart';
import '../services/address_service.dart';
import 'address_edit_page.dart';

/// 收货地址列表页面
class AddressListPage extends StatefulWidget {
  final bool selectable; // 是否为选择模式
  final Address? selectedAddress; // 已选中的地址

  const AddressListPage({
    super.key,
    this.selectable = false,
    this.selectedAddress,
  });

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  List<Address> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    AddressService.instance.addListener(_loadAddresses);
  }

  @override
  void dispose() {
    AddressService.instance.removeListener(_loadAddresses);
    super.dispose();
  }

  void _loadAddresses() {
    setState(() {
      _addresses = AddressService.instance.addresses;
    });
  }

  Future<void> _deleteAddress(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除地址'),
        content: const Text('确定要删除这个地址吗？'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('删除'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AddressService.instance.remove(id);
    }
  }

  void _editAddress(Address address) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddressEditPage(address: address),
      ),
    );
  }

  void _addAddress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddressEditPage(),
      ),
    );
  }

  void _selectAddress(Address address) {
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('收货地址'),
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildAddressList(colorScheme),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _addAddress,
            icon: const Icon(Icons.add),
            label: const Text('新增地址'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 80,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收货地址',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加新地址',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final isSelected = widget.selectedAddress?.id == address.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(color: colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: widget.selectable ? () => _selectAddress(address) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        address.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '默认',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!widget.selectable) ...[
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: colorScheme.outline,
                          ),
                          onPressed: () => _editAddress(address),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: colorScheme.error,
                          ),
                          onPressed: () => _deleteAddress(address.id!),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}