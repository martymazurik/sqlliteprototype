import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // MongoDB connection
  Db? _mongoDb;
  DbCollection? _usersCollection;
  bool _mongoInitialized = false;
  bool _mongoInitializing = false;

   Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  /// Ensure MongoDB is initialized before use
  Future<bool> _ensureMongoInitialized() async {
    // If already initialized, return success
    if (_mongoInitialized && _mongoDb != null && _mongoDb!.isConnected) {
      return true;
    }

    // If currently initializing, wait for it to complete
    if (_mongoInitializing) {
      while (_mongoInitializing) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _mongoInitialized;
    }

    // Initialize now
    return await initMongoDB();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'profile.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            firstName TEXT NOT NULL,
            lastName TEXT NOT NULL,
            email TEXT NOT NULL,
            mobileNumber TEXT NOT NULL,
            optOut INTEGER NOT NULL DEFAULT 0
          )''',
        );
      },
    );
  }

  /// Initialize MongoDB connection
  Future<bool> initMongoDB() async {
    try {

      String mongoUsername = dotenv.env['MONGO_USERNAME'] ?? '';
      String mongoPassword = dotenv.env['MONGO_PASSWORD'] ?? '';
      String databaseName = dotenv.env['DATABASE_NAME'] ?? '';
      String collectionName = dotenv.env['COLLECTION_NAME'] ?? '';

      String connectionString = 'mongodb+srv://$mongoUsername:$mongoPassword@cluster0.6j4y1lt.mongodb.net/$databaseName?retryWrites=true&w=majority&appName=Cluster0';

      _mongoDb = await Db.create(connectionString);
      await _mongoDb!.open();

      _usersCollection = _mongoDb!.collection(collectionName);

      print('MongoDB connected successfully');
      return true;
    } catch (e) {
      print('MongoDB connection failed: $e');
      return false;
    }
  }

  /// Close MongoDB connection
  Future<void> closeMongoDB() async {
    if (_mongoDb != null && _mongoDb!.isConnected) {
      await _mongoDb!.close();
    }
  }

  /// Insert to MongoDB Atlas
  Future<ObjectId?> insertToMongo(Map<String, dynamic> userData) async {
    try {
      bool initialized = await _ensureMongoInitialized();
      if (!initialized) {
        print('MongoDB not available for insert');
        return null;
      }

      final result = await _usersCollection!.insertOne(userData);
      return result.id;
    } catch (e) {
      print('MongoDB insert error: $e');
      return null;
    }
  }

  /// Original SQLite insert method
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  /// Insert to both SQLite and MongoDB
  Future<Map<String, dynamic>> insertUserBoth(User user) async {
    Map<String, dynamic> result = {
      'localSuccess': false,
      'mongoSuccess': false,
      'localError': null,
      'mongoError': null,
      'mongoId': null,
      'localId': null,
    };

    // Insert to local SQLite
    try {
      final localId = await insertUser(user);
      result['localSuccess'] = true;
      result['localId'] = localId;
    } catch (e) {
      result['localError'] = e.toString();
      print('Local SQLite insert failed: $e');
    }

    // Insert to MongoDB
    try {
      final mongoId = await insertToMongo(user.toMap());
      if (mongoId != null) {
        result['mongoSuccess'] = true;
        result['mongoId'] = mongoId.toString();
      }
    } catch (e) {
      result['mongoError'] = e.toString();
      print('MongoDB insert failed: $e');
    }

    return result;
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');

    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  /// Get user from MongoDB
  Future<Map<String, dynamic>?> getUserFromMongo(int userId) async {
    try {
      bool initialized = await _ensureMongoInitialized();
      if (!initialized) return null;

      final result = await _usersCollection!.findOne(where.eq('id', userId));
      return result;
    } catch (e) {
      print('Error getting user from MongoDB: $e');
      return null;
    }
  }

  /// Get all users from MongoDB
  Future<List<Map<String, dynamic>>> getAllUsersFromMongo() async {
    try {
      bool initialized = await _ensureMongoInitialized();
      if (!initialized) return [];

      final cursor = _usersCollection!.find();
      final results = await cursor.toList();
      return results;
    } catch (e) {
      print('Error getting all users from MongoDB: $e');
      return [];
    }
  }

  /// Update user in MongoDB
  Future<bool> updateUserInMongo(int userId, Map<String, dynamic> updates) async {
    try {
      bool initialized = await _ensureMongoInitialized();
      if (!initialized) return false;

      var modifier = modify;
      updates.forEach((key, value) {
        modifier = modifier.set(key, value);
      });

      final result = await _usersCollection!.updateOne(
          where.eq('id', userId),
          modifier
      );

      return result.isSuccess;
    } catch (e) {
      print('Error updating user in MongoDB: $e');
      return false;
    }
  }

  /// Delete user from MongoDB
  Future<bool> deleteUserFromMongo(int userId) async {
    try {
      bool initialized = await _ensureMongoInitialized();
      if (!initialized) return false;

      final result = await _usersCollection!.deleteOne(where.eq('id', userId));
      return result.isSuccess;
    } catch (e) {
      print('Error deleting user from MongoDB: $e');
      return false;
    }
  }

  /// Delete from both SQLite and MongoDB
  Future<Map<String, dynamic>> deleteUserBoth(int id) async {
    Map<String, dynamic> result = {
      'localSuccess': false,
      'mongoSuccess': false,
      'localError': null,
      'mongoError': null,
    };

    // Delete from local SQLite
    try {
      final deletedCount = await deleteUser(id);
      result['localSuccess'] = deletedCount > 0;
    } catch (e) {
      result['localError'] = e.toString();
      print('Local SQLite delete failed: $e');
    }

    // Delete from MongoDB
    try {
      final deleted = await deleteUserFromMongo(id);
      result['mongoSuccess'] = deleted;
    } catch (e) {
      result['mongoError'] = e.toString();
      print('MongoDB delete failed: $e');
    }

    return result;
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    await closeMongoDB();
  }
}