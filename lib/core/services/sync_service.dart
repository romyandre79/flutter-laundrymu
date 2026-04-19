import 'package:flutter/foundation.dart';
import 'package:kreatif_laundrymu_app/core/api/api_service.dart';
import 'package:kreatif_laundrymu_app/core/services/log_service.dart';
import 'package:kreatif_laundrymu_app/core/services/session_service.dart';
import 'package:kreatif_laundrymu_app/data/database/database_helper.dart';
import 'package:kreatif_laundrymu_app/data/models/customer.dart';
import 'package:kreatif_laundrymu_app/data/models/order.dart';
import 'package:kreatif_laundrymu_app/data/models/order_item.dart';
import 'package:kreatif_laundrymu_app/data/models/service.dart';

class SyncService {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper;
  final LogService _logService = LogService();

  SyncService({
    required ApiService apiService,
    required DatabaseHelper dbHelper,
  })  : _apiService = apiService,
        _dbHelper = dbHelper;

  Future<void> _ensureAuthenticated() async {
    final session = await SessionService.getInstance();

    final customUrl = session.getBaseUrl();
    if (customUrl != null && customUrl.isNotEmpty) {
      await _apiService.setBaseUrl(customUrl);
    }
    
    if (!session.hasCachedCredentials()) {
      throw Exception('Sesi kadaluarsa. Silakan login ulang untuk sinkronisasi.');
    }

    final username = session.getUsername()!;
    final password = session.getCachedPassword()!;

    final token = await _apiService.login(username, password);
    
    if (token != null) {
      await _apiService.setAuthToken(token);
    } else {
      throw Exception('Gagal login ke server. Periksa koneksi internet atau kredensial Anda.');
    }
  }

  // Upload unsynced orders
  Future<int> uploadOrders() async {
    await _ensureAuthenticated();

    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    if (maps.isEmpty) return 0;

    int successCount = 0;

    for (final map in maps) {
      try {
        final order = Order.fromMap(map);
        
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [order.id],
        );
        final items = itemMaps.map((e) => OrderItem.fromMap(e)).toList();
        
        final payload = order.toMap();
        payload['items'] = items.map((e) => e.toMap()).toList();
        
        final response = await _apiService.executeFlow('pos_sync_orders', 'pos', payload);
        
        if (response.data['code'] == 200) {
          final serverId = response.data['data']['data']['id']; 
          
          await db.update(
            'orders',
            {
              'is_synced': 1,
              'server_id': serverId,
            },
            where: 'id = ?',
            whereArgs: [order.id],
          );
          successCount++;
        }
      } catch (e) {
        await _logService.log('SYNC_ERROR', 'Order ${map['invoice_no']}: $e');
      }
    }

    return successCount;
  }

  // Download master data
  Future<void> downloadMasterData() async {
    await _ensureAuthenticated();
    await _downloadServices();
    await _downloadCustomers();
  }
  
  Future<void> _downloadServices() async {
    try {
      final response = await _apiService.executeFlow('pos_get_products', 'pos', {});
      
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data']['data'];
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          for (final item in data) {
            final List<Map<String, dynamic>> existing = await txn.query(
              'services',
              where: 'server_id = ?',
              whereArgs: [item['id']],
            );

            final price = int.tryParse(item['price'].toString()) ?? 0;
            final duration = int.tryParse(item['duration_days']?.toString() ?? '3') ?? 3;

            final service = Service(
              name: item['name'],
              unit: ServiceUnitExtension.fromString(item['unit'] ?? 'kg'),
              price: price,
              durationDays: duration,
              isActive: (item['is_active']?.toString() ?? '1') == '1',
              barcode: item['barcode'],
              serverId: item['id'],
            );

            if (existing.isNotEmpty) {
              final updateMap = service.toMap()..remove('id');
              await txn.update('services', updateMap, where: 'server_id = ?', whereArgs: [item['id']]);
            } else {
              await txn.insert('services', service.toMap());
            }
          }
        });
      }
    } catch (e) {
      await _logService.log('SYNC_ERROR', 'Services: $e');
    }
  }

  Future<void> _downloadCustomers() async {
    try {
      final response = await _apiService.executeFlow('pos_get_customers', 'pos', {});
      
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data']['data'];
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          for (final item in data) {
            final List<Map<String, dynamic>> existing = await txn.query(
              'customers',
              where: 'server_id = ?',
              whereArgs: [item['id']],
            );

            final customer = Customer(
              name: item['name'],
              phone: item['phone'],
              address: item['address'],
              notes: item['notes'],
              serverId: item['id'],
            );

            if (existing.isNotEmpty) {
              final updateMap = customer.toMap()..remove('id');
              await txn.update('customers', updateMap, where: 'server_id = ?', whereArgs: [item['id']]);
            } else {
              await txn.insert('customers', customer.toMap());
            }
          }
        });
      }
    } catch (e) {
      await _logService.log('SYNC_ERROR', 'Customers: $e');
    }
  }
}
