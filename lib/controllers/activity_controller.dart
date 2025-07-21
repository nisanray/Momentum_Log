import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'auth_controller.dart';
import 'connectivity_controller.dart';
import '../models/daily_log.dart';
import '../models/task_entry.dart';
import '../main.dart'; // For dailyLogsBoxName

class ActivityController with ChangeNotifier {
  final AuthController _authController;
  final ConnectivityController _connectivityController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Box<DailyLog> _dailyLogsHiveBox;

  String? _currentUserId;
  List<DailyLog> _currentUserLogsFromHive = []; // Raw data from Hive
  bool _isLoading = false;
  String? _syncStatusMessage;
  Timer? _syncStatusTimer;

  // --- Pre-sorted/cached data for UI ---
  List<TaskEntry> _sortedTodayTasksCache = [];
  Map<String, List<TaskEntry>> _sortedActivitiesByDateCache = {};
  List<DailyLog> _sortedAllCurrentUserLogsCache = [];
  // ---

  // Public Getters
  bool get isLoading => _isLoading;
  String? get syncStatusMessage => _syncStatusMessage;
  String get currentDateKey => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String get displayDate => DateFormat('MMMM d, yyyy').format(DateTime.now());

  // Getter for today's log (not sorted tasks, just the log object)
  DailyLog? get todayLogObject {
    final todayKey = currentDateKey;
    return _currentUserLogsFromHive.any((log) => log.dateString == todayKey && log.userId == _currentUserId)
        ? _currentUserLogsFromHive.firstWhere((log) => log.dateString == todayKey && log.userId == _currentUserId)
        : null;
  }

  // Getters for pre-sorted data
  List<TaskEntry> get sortedTodayTasks => _sortedTodayTasksCache;
  Map<String, List<TaskEntry>> get sortedActivitiesByDate => _sortedActivitiesByDateCache;
  List<DailyLog> get sortedAllLogsForDisplay => _sortedAllCurrentUserLogsCache;


  ActivityController({required AuthController authController, required ConnectivityController connectivityController})
      : _authController = authController,
        _connectivityController = connectivityController {
    _dailyLogsHiveBox = Hive.box<DailyLog>(dailyLogsBoxName);
    _currentUserId = _authController.userId; // Initialize based on AuthController's current state
    _initializeControllerData();
  }

  Future<void> _initializeControllerData() async {
    await _loadLogsFromHiveAndSort(); // This will also sort and notify if needed
    if (_connectivityController.isOnline && _currentUserId != null) {
      await syncAllData(); // Sync after initial load
    }
  }


  void authControllerUpdated(String? newUserId) {
    if (_currentUserId != newUserId) {
      _currentUserId = newUserId;
      _currentUserLogsFromHive.clear();
      _clearSortedCaches(); // Clear sorted caches

      if (newUserId != null) {
        _setSyncStatus("Fetching data...", autoClear: false);
        _loadLogsFromHiveAndSort().then((_) { // Load, sort, and then sync
          if (_connectivityController.isOnline) {
            syncAllData();
          } else {
            _setSyncStatus("Offline. Displaying local data.", durationSeconds: 5);
          }
        });
      } else {
        _setSyncStatus("User logged out.", durationSeconds: 3);
        notifyListeners(); // Notify UI of cleared data
      }
    }
  }

  void _clearSortedCaches() {
    _sortedTodayTasksCache = [];
    _sortedActivitiesByDateCache = {};
    _sortedAllCurrentUserLogsCache = [];
  }

  // Central method to update sorted caches whenever _currentUserLogsFromHive changes
  void _updateAndSortLocalDataCaches() {
    // Sort today's tasks
    final currentTodayLog = todayLogObject;
    if (currentTodayLog != null) {
      _sortedTodayTasksCache = List<TaskEntry>.from(currentTodayLog.tasks)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    } else {
      _sortedTodayTasksCache = [];
    }

    // Sort activitiesByDateForCurrentUser
    Map<String, List<TaskEntry>> grouped = {};
    for (var log in _currentUserLogsFromHive) {
      if(log.userId == _currentUserId) { // Ensure only current user's logs are processed
        grouped[log.dateString] = List<TaskEntry>.from(log.tasks)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    }
    var sortedKeys = grouped.keys.toList()..sort((a,b) => b.compareTo(a)); // Most recent date first
    _sortedActivitiesByDateCache.clear();
    for(var key in sortedKeys) {
      _sortedActivitiesByDateCache[key] = grouped[key]!;
    }

    // Sort allCurrentUserLogs for display
    _sortedAllCurrentUserLogsCache = _currentUserLogsFromHive
        .where((log) => log.userId == _currentUserId) // Filter again for safety
        .toList()
      ..sort((a,b) => b.dateString.compareTo(a.dateString)); // Most recent date first

    // debugPrint("ActivityController: Data caches updated. Today: ${_sortedTodayTasksCache.length}, ByDate: ${_sortedActivitiesByDateCache.length}");
  }


  void _setSyncStatus(String message, {int durationSeconds = 3, bool autoClear = true}) {
    _syncStatusMessage = message;
    notifyListeners(); // Notify for sync status message change
    _syncStatusTimer?.cancel();
    if (autoClear) {
      _syncStatusTimer = Timer(Duration(seconds: durationSeconds), () {
        if (mounted) { // Check if controller is still active
          _syncStatusMessage = null;
          notifyListeners();
        }
      });
    }
  }

  // Helper to ensure mounted check for timers (though ChangeNotifier doesn't have 'mounted')
  // For simplicity, we assume if timer fires, controller is likely still used.
  // Proper timer cancellation is in dispose().
  bool get mounted => true;


  Future<void> _loadLogsFromHiveAndSort() async {
    if (_currentUserId == null) {
      _currentUserLogsFromHive = [];
      _updateAndSortLocalDataCaches();
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners(); // Notify for loading state
    try {
      _currentUserLogsFromHive = _dailyLogsHiveBox.values.where((log) => log.userId == _currentUserId).toList();
      debugPrint("ActivityController: Loaded ${_currentUserLogsFromHive.length} logs from Hive for user $_currentUserId");
    } catch (e) {
      debugPrint("ActivityController: Error loading logs from Hive: $e");
      _currentUserLogsFromHive = [];
    }
    _updateAndSortLocalDataCaches(); // Sort after loading
    _isLoading = false;
    notifyListeners(); // Notify data is loaded and sorted
  }

  // To be called when a single log in _currentUserLogsFromHive is added or updated
  void _updateSingleLogAndResort(DailyLog updatedLog) {
    int index = _currentUserLogsFromHive.indexWhere((l) => l.dateString == updatedLog.dateString && l.userId == updatedLog.userId);
    if (index != -1) {
      _currentUserLogsFromHive[index] = updatedLog;
    } else {
      _currentUserLogsFromHive.add(updatedLog);
    }
    _updateAndSortLocalDataCaches(); // Re-sort all derived lists
  }

  Future<String?> addTask(String description) async {
    if (_currentUserId == null) return "User not authenticated.";
    _isLoading = true;
    notifyListeners();

    final task = TaskEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      timestamp: DateTime.now(),
    );
    final todayKey = currentDateKey;
    final logKey = todayKey + _currentUserId!; // Composite key for Hive

    DailyLog log = _currentUserLogsFromHive.firstWhere(
            (l) => l.dateString == todayKey && l.userId == _currentUserId,
        orElse: () => DailyLog(userId: _currentUserId!, dateString: todayKey, tasks: [], isSynced: false, lastModified: DateTime.now())
    );

    List<TaskEntry> updatedTasks = List.from(log.tasks)..add(task);
    DailyLog updatedLog = DailyLog(
      userId: log.userId,
      dateString: log.dateString,
      tasks: updatedTasks,
      isSynced: false,
      lastModified: DateTime.now(),
    );

    try {
      await _dailyLogsHiveBox.put(logKey, updatedLog);
      _updateSingleLogAndResort(updatedLog); // Update internal list and re-sort caches
      _setSyncStatus("Activity saved locally.", durationSeconds: 2);

      if (_connectivityController.isOnline) {
        await _syncLogToFirestore(updatedLog); // This will also update isSynced in Hive and re-sort
      } else {
        _setSyncStatus("Offline. Activity saved locally.", durationSeconds: 3);
      }
      return null;
    } catch (e) {
      debugPrint("Error adding task: $e");
      return "Failed to add activity: $e";
    } finally {
      _isLoading = false;
      notifyListeners(); // Final notification for UI state
    }
  }

  Future<String?> deleteTask(String dateString, TaskEntry taskToDelete) async {
    if (_currentUserId == null) return "User not authenticated.";
    _isLoading = true;
    notifyListeners();

    final logKey = dateString + _currentUserId!;
    DailyLog? log = _dailyLogsHiveBox.get(logKey); // Get from Hive directly

    if (log == null) {
      _isLoading = false;
      notifyListeners();
      return "Log not found for deletion.";
    }

    List<TaskEntry> updatedTasks = List.from(log.tasks)..removeWhere((task) => task.id == taskToDelete.id);
    DailyLog updatedLog = DailyLog(
        userId: log.userId,
        dateString: log.dateString,
        tasks: updatedTasks,
        isSynced: false,
        lastModified: DateTime.now()
    );

    try {
      if (updatedTasks.isEmpty) {
        await _dailyLogsHiveBox.delete(logKey);
        _currentUserLogsFromHive.removeWhere((l) => l.dateString == dateString && l.userId == _currentUserId);
        _updateAndSortLocalDataCaches(); // Re-sort after removal
        _setSyncStatus("Day's log cleared locally.", durationSeconds: 2);
      } else {
        await _dailyLogsHiveBox.put(logKey, updatedLog);
        _updateSingleLogAndResort(updatedLog);
        _setSyncStatus("Activity deleted locally.", durationSeconds: 2);
      }

      if (_connectivityController.isOnline) {
        if (updatedTasks.isEmpty) {
          await _firestore.collection('dailyLogs').doc(logKey).delete();
          _setSyncStatus("Day's log removed from cloud.", durationSeconds: 2);
        } else {
          await _syncLogToFirestore(updatedLog);
        }
      } else {
        _setSyncStatus("Offline. Deletion saved locally.", durationSeconds: 3);
      }
      return null;
    } catch (e) {
      debugPrint("Error deleting task: $e");
      return "Failed to delete activity: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> _syncLogToFirestore(DailyLog log) async {
    if (_currentUserId == null) return;
    final logKey = log.dateString + _currentUserId!;
    // Optimistically update local state before Firestore call for faster UI response
    final tempSyncedLog = DailyLog(
        userId: log.userId, dateString: log.dateString, tasks: log.tasks,
        isSynced: true, lastModified: log.lastModified ?? DateTime.now()
    );
    await _dailyLogsHiveBox.put(logKey, tempSyncedLog); // Update Hive first
    _updateSingleLogAndResort(tempSyncedLog); // Update caches and re-sort
    // No notifyListeners here yet, will be called in finally or on error

    try {
      await _firestore.collection('dailyLogs').doc(logKey).set(tempSyncedLog.toJson()); // Use tempSyncedLog
      _setSyncStatus("Data synced with cloud.", durationSeconds: 2);
    } catch (e) {
      debugPrint("Error syncing log $logKey to Firestore: $e");
      // Revert optimistic update if Firestore fails
      final revertedLog = DailyLog(
          userId: log.userId, dateString: log.dateString, tasks: log.tasks,
          isSynced: false, // Mark as not synced
          lastModified: log.lastModified ?? DateTime.now()
      );
      await _dailyLogsHiveBox.put(logKey, revertedLog);
      _updateSingleLogAndResort(revertedLog);
      _setSyncStatus("Sync error for $logKey. Reverted.", durationSeconds: 4);
    } finally {
      notifyListeners(); // Notify after sync attempt or error handling
    }
  }

  Future<void> syncAllData() async {
    if (!_connectivityController.isOnline || _currentUserId == null) {
      _setSyncStatus(_connectivityController.isOnline ? "User not identified." : "Offline.", durationSeconds: 3);
      return;
    }
    _isLoading = true;
    _setSyncStatus("Syncing all data...", autoClear: false);
    // notifyListeners(); // isLoading change will be notified by caller or next lines

    try {
      final querySnapshot = await _firestore.collection('dailyLogs').where('userId', isEqualTo: _currentUserId).get();
      Map<String, DailyLog> firestoreLogs = {
        for (var doc in querySnapshot.docs) doc.id: DailyLog.fromJson(doc.data())
      };

      List<DailyLog> hiveLogsToProcess = List.from(_dailyLogsHiveBox.values.where((log) => log.userId == _currentUserId));

      for (DailyLog hiveLog in hiveLogsToProcess) {
        final logKey = hiveLog.dateString + _currentUserId!;
        DailyLog? firestoreLog = firestoreLogs[logKey];
        DateTime hiveMod = hiveLog.lastModified ?? DateTime(1970);
        DateTime firestoreMod = firestoreLog?.lastModified ?? DateTime(1970);

        if (firestoreLog == null || (hiveMod.isAfter(firestoreMod) && !hiveLog.isSynced)) {
          debugPrint("SyncAll: Uploading ${hiveLog.dateString}");
          // Firestore will be updated, and then _syncLogToFirestore will update Hive's isSynced
          await _syncLogToFirestore(hiveLog); // This handles updating Hive isSynced and re-sorting
        } else if (firestoreMod.isAfter(hiveMod)) {
          debugPrint("SyncAll: Downloading ${firestoreLog.dateString}");
          await _dailyLogsHiveBox.put(logKey, firestoreLog);
          // _updateSingleLogAndResort(firestoreLog); // This will be handled by _loadLogsFromHiveAndSort later
        }
        firestoreLogs.remove(logKey);
      }

      for (var entry in firestoreLogs.entries) {
        debugPrint("SyncAll: Adding new from Firestore ${entry.value.dateString}");
        await _dailyLogsHiveBox.put(entry.key, entry.value);
      }
      _setSyncStatus("Sync complete.", durationSeconds: 3);
    } catch (e) {
      debugPrint("Error during full sync: $e");
      _setSyncStatus("Full sync failed.", durationSeconds: 5);
    } finally {
      _isLoading = false;
      // Reload all logs from Hive and re-sort everything to ensure consistency
      await _loadLogsFromHiveAndSort();
      // notifyListeners() is called by _loadLogsFromHiveAndSort
    }
  }

  @override
  void dispose() {
    _syncStatusTimer?.cancel();
    super.dispose();
  }
}