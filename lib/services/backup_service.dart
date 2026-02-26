import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> getAllData() async {
    final Map<String, String> allData = {};

    // Get all keys from secure storage
    final keys = await _storage.readAll();
    allData.addAll(keys);

    return allData;
  }

  Future<String> createBackup() async {
    try {
      final data = await getAllData();
      final jsonData = jsonEncode(data);

      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/memocare_backup_${DateTime.now().millisecondsSinceEpoch}.json');

      await backupFile.writeAsString(jsonData);
      return backupFile.path;
    } catch (e) {
      throw Exception('Backup failed: $e');
    }
  }

  Future<bool> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) throw Exception('Backup file not found');

      final jsonData = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonData);

      // Clear existing data
      await _storage.deleteAll();

      // Restore data
      for (var entry in data.entries) {
        await _storage.write(key: entry.key, value: entry.value.toString());
      }

      return true;
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }

  Future<void> shareBackup() async {
    try {
      final backupPath = await createBackup();
      await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'MemoCare Data Backup - ${DateTime.now().toLocal()}',
      );
    } catch (e) {
      throw Exception('Share failed: $e');
    }
  }
}