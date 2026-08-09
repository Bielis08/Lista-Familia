import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:lista_familia/repositories/local_product_repository.dart';
import 'package:lista_familia/repositories/remote_product_repository.dart';
import 'package:lista_familia/services/supabase_service.dart';

enum SyncStatus { idle, syncing, synced, error }

class SyncService {
  final LocalProductRepository _local;
  final RemoteProductRepository _remote;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<dynamic>>? _realtimeSubscription;
  bool _isConnected = true;
  bool _isSyncing = false;
  int _pendingCount = 0;
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;

  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final StreamController<int> _pendingController = StreamController<int>.broadcast();
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();

  SyncService(AppDatabase db)
      : _local = LocalProductRepository(db),
        _remote = RemoteProductRepository() {
    _initConnectivity();
    _setupRealtime();
    _startPeriodicSync();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _isConnected = results.any((r) => r != ConnectivityResult.none);
      _connectivityController.add(_isConnected);
    } catch (_) {
      _isConnected = true;
    }
    _setupConnectivity();
    await _updatePendingCount();
  }

  void _setupConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasConnected = _isConnected;
      _isConnected = results.any((r) => r != ConnectivityResult.none);
      _connectivityController.add(_isConnected);

      if (!wasConnected && _isConnected) {
        syncNow();
      }
    });
  }

  void _setupRealtime() {
    try {
      _realtimeSubscription = SupabaseService.client
          .from('products')
          .stream(primaryKey: ['id'])
          .order('position', ascending: true)
          .listen(
        (_) async {
          if (_isConnected && !_isSyncing) {
            await _pullRemoteRecords();
            await _updatePendingCount();
          }
        },
        onError: (_) {
          // Realtime connection error - will fall back to periodic sync
        },
      );
    } catch (e) {
      // Realtime not available, rely on periodic sync
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && !_isSyncing) {
        syncNow();
      }
    });
  }

  bool get isConnected => _isConnected;
  int get pendingCount => _pendingCount;
  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  Stream<int> get onPendingChanged => _pendingController.stream;
  Stream<SyncStatus> get onStatusChanged => _statusController.stream;

  Future<void> syncNow() async {
    if (!_isConnected || _isSyncing) return;
    _isSyncing = true;
    _status = SyncStatus.syncing;
    _statusController.add(_status);

    try {
      await _pushDirtyRecords();
      await _pullRemoteRecords();
      _lastSyncTime = DateTime.now();
      _status = SyncStatus.synced;
      _statusController.add(_status);
    } catch (e) {
      _status = SyncStatus.error;
      _statusController.add(_status);
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
    }
  }

  Future<void> _updatePendingCount() async {
    final dirty = await _local.getDirty();
    final deleted = await _local.getDeletedDirty();
    _pendingCount = dirty.length + deleted.length;
    _pendingController.add(_pendingCount);
  }

  Future<void> _pushDirtyRecords() async {
    final dirtyProducts = await _local.getDirty();

    for (final product in dirtyProducts) {
      try {
        await _remote.updateAll(product);
        await _local.markSynced(product.id);
      } catch (e) {
        // Will retry on next sync cycle
      }
    }

    final deletedProducts = await _local.getDeletedDirty();
    for (final product in deletedProducts) {
      try {
        await _remote.deleteProduct(product.id);
        await _local.hardDelete(product.id);
      } catch (e) {
        // Will retry on next sync cycle
      }
    }
  }

  Future<void> _pullRemoteRecords() async {
    try {
      final remoteProducts = await _remote.getAll();
      await _local.syncFromRemote(remoteProducts);
    } catch (e) {
      // Will retry on next sync cycle
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _realtimeSubscription?.cancel();
    _connectivityController.close();
    _pendingController.close();
    _statusController.close();
  }
}