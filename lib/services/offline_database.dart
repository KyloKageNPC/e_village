import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class OfflineDatabase {
  static final OfflineDatabase _instance = OfflineDatabase._internal();
  factory OfflineDatabase() => _instance;
  OfflineDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'e_village_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cached transactions
    await db.execute('''
      CREATE TABLE cached_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Pending operations (to be synced when online)
    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Cached loans
    await db.execute('''
      CREATE TABLE cached_loans (
        id TEXT PRIMARY KEY,
        borrower_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        amount REAL NOT NULL,
        interest_rate REAL NOT NULL,
        duration_months INTEGER NOT NULL,
        purpose TEXT NOT NULL,
        status TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Cached savings accounts
    await db.execute('''
      CREATE TABLE cached_savings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        balance REAL NOT NULL,
        total_contributions REAL NOT NULL,
        total_withdrawals REAL NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Cached messages
    await db.execute('''
      CREATE TABLE cached_messages (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL,
        message_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    debugPrint('✅ Offline database created successfully');
  }

  // ==================== TRANSACTIONS ====================

  Future<void> cacheTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.insert(
      'cached_transactions',
      {
        'id': transaction['id'],
        'user_id': transaction['user_id'],
        'group_id': transaction['group_id'],
        'type': transaction['type'],
        'amount': transaction['amount'],
        'description': transaction['description'],
        'status': transaction['status'],
        'transaction_date': transaction['transaction_date'],
        'data': jsonEncode(transaction),
        'synced': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedTransactions({
    required String userId,
    int limit = 50,
  }) async {
    final db = await database;
    final results = await db.query(
      'cached_transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'transaction_date DESC',
      limit: limit,
    );

    return results.map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>).toList();
  }

  // ==================== PENDING OPERATIONS ====================

  Future<int> addPendingOperation({
    required String operationType,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    return await db.insert('pending_operations', {
      'operation_type': operationType,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    final results = await db.query(
      'pending_operations',
      orderBy: 'created_at ASC',
    );

    return results.map((row) {
      return {
        'id': row['id'],
        'operation_type': row['operation_type'],
        'data': jsonDecode(row['data'] as String),
        'created_at': row['created_at'],
        'retry_count': row['retry_count'],
      };
    }).toList();
  }

  Future<void> removePendingOperation(int id) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_operations SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // ==================== LOANS ====================

  Future<void> cacheLoan(Map<String, dynamic> loan) async {
    final db = await database;
    await db.insert(
      'cached_loans',
      {
        'id': loan['id'],
        'borrower_id': loan['borrower_id'],
        'group_id': loan['group_id'],
        'amount': loan['amount'],
        'interest_rate': loan['interest_rate'],
        'duration_months': loan['duration_months'],
        'purpose': loan['purpose'],
        'status': loan['status'],
        'data': jsonEncode(loan),
        'synced': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedLoans({
    required String borrowerId,
  }) async {
    final db = await database;
    final results = await db.query(
      'cached_loans',
      where: 'borrower_id = ?',
      whereArgs: [borrowerId],
      orderBy: 'created_at DESC',
    );

    return results.map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>).toList();
  }

  // ==================== SAVINGS ====================

  Future<void> cacheSavingsAccount(Map<String, dynamic> savings) async {
    final db = await database;
    final key = '${savings['user_id']}_${savings['group_id']}';
    await db.insert(
      'cached_savings',
      {
        'id': key,
        'user_id': savings['user_id'],
        'group_id': savings['group_id'],
        'balance': savings['balance'],
        'total_contributions': savings['total_contributions'],
        'total_withdrawals': savings['total_withdrawals'],
        'data': jsonEncode(savings),
        'synced': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedSavingsAccount({
    required String userId,
    required String groupId,
  }) async {
    final db = await database;
    final key = '${userId}_$groupId';
    final results = await db.query(
      'cached_savings',
      where: 'id = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return jsonDecode(results.first['data'] as String) as Map<String, dynamic>;
  }

  // ==================== MESSAGES ====================

  Future<void> cacheMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      'cached_messages',
      {
        'id': message['id'],
        'group_id': message['group_id'],
        'sender_id': message['sender_id'],
        'content': message['content'],
        'message_type': message['message_type'],
        'created_at': message['created_at'],
        'data': jsonEncode(message),
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedMessages({
    required String groupId,
    int limit = 100,
  }) async {
    final db = await database;
    final results = await db.query(
      'cached_messages',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return results.map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>).toList();
  }

  // ==================== UTILITY ====================

  Future<int> getPendingOperationsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_operations');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cached_transactions');
    await db.delete('cached_loans');
    await db.delete('cached_savings');
    await db.delete('cached_messages');
    debugPrint('✅ All cache cleared');
  }

  Future<void> clearPendingOperations() async {
    final db = await database;
    await db.delete('pending_operations');
    debugPrint('✅ All pending operations cleared');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
