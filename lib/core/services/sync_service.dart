import 'package:flutter/foundation.dart';
import 'package:kreatif_laundrymu_app/core/services/api_service.dart';
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
    await _logService.log('SYNC', 'Starting authentication...');
    final session = await SessionService.getInstance();
    
    // Check if we have cached credentials
    if (!session.hasCachedCredentials()) {
      await _logService.log('SYNC', 'ERROR: No cached credentials found. User needs to re-login.');
      throw Exception('Sesi kadaluarsa. Silakan login ulang ke aplikasi untuk melakukan sinkronisasi.');
    }

    final username = session.getUsername()!;
    final password = session.getCachedPassword()!;
    await _logService.log('SYNC', 'Attempting server login for user: $username');

    // Attempt login to server
    final token = await _apiService.login(username, password);
    
    if (token != null) {
      _apiService.setAuthToken(token);
      await _logService.log('SYNC', 'Authentication successful.');
    } else {
      await _logService.log('SYNC', 'ERROR: Authentication failed. Server returned no token.');
      throw Exception('Gagal login ke server. Periksa koneksi internet atau kredensial Anda.');
    }
  }

  // Upload unsynced orders
  Future<int> uploadOrders() async {
    await _ensureAuthenticated();

    final db = await _dbHelper.database;
    
    // Get unsynced orders
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    await _logService.log('SYNC', 'Found ${maps.length} unsynced orders.');
    if (maps.isEmpty) return 0;

    int successCount = 0;

    for (final map in maps) {
      try {
        final order = Order.fromMap(map);
        await _logService.log('SYNC', 'Uploading order: ${map['invoice_no']}');
        
        // Get order items
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [order.id],
        );
        final items = itemMaps.map((e) => OrderItem.fromMap(e)).toList();
        
        // Prepare payload
        final payload = order.toMap();
        payload['items'] = items.map((e) => e.toMap()).toList();
        
        // Send to server using executeFlow
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
          await _logService.log('SYNC', 'Order ${map['invoice_no']} synced successfully (server_id: $serverId)');
        }
      } catch (e) {
        await _logService.log('SYNC', 'ERROR uploading order ${map['invoice_no']}: $e');
        debugPrint('Error uploading order ${map['invoice_no']}: $e');
      }
    }

    await _logService.log('SYNC', 'Upload complete. $successCount/${maps.length} orders synced.');
    return successCount;
  }

  // Download master data (Services, Customers)
  Future<void> downloadMasterData() async {
    await _ensureAuthenticated();
    await _logService.log('SYNC', 'Starting master data download...');
    await _downloadServices();
    await _downloadCustomers();
    await _logService.log('SYNC', 'Master data download complete.');
  }

  Future<void> _downloadServices() async {
    try {
      final response = await _apiService.executeFlow('pos_get_products', 'pos', {});
      
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data']['data'];
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          for (final item in data) {
            // Check if exists by server_id
            final List<Map<String, dynamic>> existing = await txn.query(
              'services',
              where: 'server_id = ?',
              whereArgs: [item['id']],
            );

            // Robust parsing
            final price = int.tryParse(item['price'].toString()) ?? 0;
            final durationDays = int.tryParse(item['duration_days'].toString()) ?? 3;
            final isActive = (item['is_active'] == 1 || item['is_active'] == true);

            final service = Service(
              name: item['name'],
              unit: ServiceUnitExtension.fromString(item['unit'] ?? 'kg'),
              price: price,
              durationDays: durationDays,
              isActive: isActive,
              // serverId: item['id'], // Need to add server_id to Service model
            );
            
            final serviceMap = service.toMap();
            serviceMap['server_id'] = item['id'];

            if (existing.isNotEmpty) {
              // Update
              serviceMap.remove('id'); // Keep local ID
              await txn.update(
                'services',
                serviceMap,
                where: 'server_id = ?',
                whereArgs: [item['id']],
              );
            } else {
              // Insert
              await txn.insert('services', serviceMap);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error downloading services: $e');
      rethrow;
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
              // serverId: item['id'], // Need to add server_id to Customer model
            );
            
            final customerMap = customer.toMap();
            customerMap['server_id'] = item['id'];

            if (existing.isNotEmpty) {
              customerMap.remove('id');
              await txn.update(
                'customers',
                customerMap,
                where: 'server_id = ?',
                whereArgs: [item['id']],
              );
            } else {
              await txn.insert('customers', customerMap);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error downloading customers: $e');
      rethrow;
    }
  }
}
