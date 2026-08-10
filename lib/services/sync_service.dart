import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:lista_familia/repositories/local_product_repository.dart';
import 'package:lista_familia/repositories/remote_product_repository.dart';
import 'package:lista_familia/services/supabase_service.dart';

enum SyncStatus { idle, syncing, synced, error }

class SyncService {
  static const Duration _realtimeDebounceDelay = Duration(milliseconds: 600);

  final LocalProductRepository _local;
  final RemoteProductRepository _remote;
  Timer? _syncTimer;
  Timer? _realtimeProductsDebounce;
  Timer? _realtimeListsDebounce;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<dynamic>>? _realtimeProductsSubscription;
  StreamSubscription<List<dynamic>>? _realtimeListsSubscription;
  bool _isConnected = true;
  bool _isSyncing = false;
  bool _isPullingProducts = false;
  bool _isPullingLists = false;
  int _pendingCount = 0;
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  bool _disposed = false;

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
      if (!_disposed) _connectivityController.add(_isConnected);
    } catch (_) {
      _isConnected = true;
    }
    if (!_disposed) _setupConnectivity();
    await _updatePendingCount();
  }

  void _setupConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasConnected = _isConnected;
      _isConnected = results.any((r) => r != ConnectivityResult.none);
      if (!_disposed) _connectivityController.add(_isConnected);

      if (!wasConnected && _isConnected) {
        syncNow();
      }
    });
  }

  void _setupRealtime() {
    try {
      _realtimeProductsSubscription = SupabaseService.client
          .from('products')
          .stream(primaryKey: ['id'])
          .order('position', ascending: true)
          .listen(
        (_) => _scheduleProductsPull(),
        onError: (Object e) {
          debugPrint('Realtime products error: $e');
        },
      );
    } catch (e) {
      debugPrint('Realtime products setup error: $e');
    }

    try {
      _realtimeListsSubscription = SupabaseService.client
          .from('lists')
          .stream(primaryKey: ['id'])
          .order('position', ascending: true)
          .listen(
        (_) => _scheduleListsPull(),
        onError: (Object e) {
          debugPrint('Realtime lists error: $e');
        },
      );
    } catch (e) {
      debugPrint('Realtime lists setup error: $e');
    }
  }

  void _scheduleProductsPull() {
    if (_disposed) return;
    _realtimeProductsDebounce?.cancel();
    _realtimeProductsDebounce = Timer(_realtimeDebounceDelay, () {
      if (_disposed || !_isConnected || _isSyncing) return;
      unawaited(_runProductsPull());
    });
  }

  void _scheduleListsPull() {
    if (_disposed) return;
    _realtimeListsDebounce?.cancel();
    _realtimeListsDebounce = Timer(_realtimeDebounceDelay, () {
      if (_disposed || !_isConnected || _isSyncing) return;
      unawaited(_runListsPull());
    });
  }

  Future<void> _runProductsPull() async {
    if (_isPullingProducts) return;
    _isPullingProducts = true;
    try {
      await _pullRemoteRecords();
    } catch (e) {
      debugPrint('Realtime products pull failed: $e');
    } finally {
      _isPullingProducts = false;
      await _updatePendingCount();
    }
  }

  Future<void> _runListsPull() async {
    if (_isPullingLists) return;
    _isPullingLists = true;
    try {
      await _pullRemoteLists();
    } catch (e) {
      debugPrint('Realtime lists pull failed: $e');
    } finally {
      _isPullingLists = false;
      await _updatePendingCount();
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && !_isSyncing && !_disposed) {
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
    if (!_isConnected || _isSyncing || _disposed) return;
    _isSyncing = true;
    _status = SyncStatus.syncing;
    if (!_disposed) _statusController.add(_status);

    try {
      await _pushDirtyRecords();
      await _pullRemoteRecords();
      await _pushDirtyLists();
      await _pullRemoteLists();
      _lastSyncTime = DateTime.now();
      _status = SyncStatus.synced;
      if (!_disposed) _statusController.add(_status);
    } catch (e) {
      debugPrint('Sync error: $e');
      _status = SyncStatus.error;
      if (!_disposed) _statusController.add(_status);
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
    }
  }

  Future<void> _updatePendingCount() async {
    if (_disposed) return;
    try {
      final dirty = await _local.getDirty();
      final deleted = await _local.getDeletedDirty();
      final dirtyLists = await _local.getDirtyLists();
      final deletedLists = await _local.getDeletedDirtyLists();
      _pendingCount = dirty.length + deleted.length + dirtyLists.length + deletedLists.length;
      if (!_disposed) {
        _pendingController.add(_pendingCount);
      }
    } catch (_) {}
  }

  Future<void> _pushDirtyRecords() async {
    final dirtyProducts = await _local.getDirty();

    for (final product in dirtyProducts) {
      try {
        await _remote.updateAll(product);
        await _local.markSynced(product.id);
      } catch (e) {
        debugPrint('Push dirty product ${product.id} failed: $e');
      }
    }

    final deletedProducts = await _local.getDeletedDirty();
    for (final product in deletedProducts) {
      try {
        await _remote.deleteProduct(product.id);
        await _local.hardDelete(product.id);
      } catch (e) {
        debugPrint('Push deleted product ${product.id} failed: $e');
      }
    }
  }

  Future<void> _pushDirtyLists() async {
    final dirtyLists = await _local.getDirtyLists();
    for (final list in dirtyLists) {
      try {
        await _remote.updateList(
          list.id,
          name: list.name,
          icon: list.icon,
          position: list.position,
          createdAt: list.createdAt,
        );
        await _local.markListSynced(list.id);
      } catch (e) {
        debugPrint('Push dirty list ${list.id} failed: $e');
      }
    }

    final deletedLists = await _local.getDeletedDirtyLists();
    for (final list in deletedLists) {
      try {
        await _remote.deleteProductsByList(list.id);
        await _remote.deleteList(list.id);
        await _local.markListSynced(list.id);
      } catch (e) {
        debugPrint('Push deleted list ${list.id} failed: $e');
      }
    }
  }

  Future<void> _pullRemoteRecords() async {
    final remoteProducts = await _remote.getAll();
    await _local.syncFromRemote(remoteProducts);
  }

  Future<void> _pullRemoteLists() async {
    final remoteLists = await _remote.getLists();
    await _local.syncListsFromRemote(remoteLists);
  }

  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
    _realtimeProductsDebounce?.cancel();
    _realtimeListsDebounce?.cancel();
    _connectivitySubscription?.cancel();
    _realtimeProductsSubscription?.cancel();
    _realtimeListsSubscription?.cancel();
    _connectivityController.close();
    _pendingController.close();
    _statusController.close();
  }
}
