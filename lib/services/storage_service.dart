// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prompt_history.dart';

class StorageService {
  static const String _historyKey = 'prompt_history';

  static Future<List<PromptHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      return historyJson.map((itemJson) {
        final data = jsonDecode(itemJson) as Map<String, dynamic>;
        return PromptHistoryItem.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  static Future<void> saveHistoryItem(PromptHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHistory = await getHistory();

      // Add new item at the beginning
      currentHistory.insert(0, item);

      // Keep only last 50 items
      if (currentHistory.length > 50) {
        currentHistory.removeRange(50, currentHistory.length);
      }

      final historyJson =
          currentHistory.map((item) {
            return jsonEncode(item.toJson());
          }).toList();

      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  static Future<void> deleteHistoryItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHistory = await getHistory();

      currentHistory.removeWhere((item) => item.id == id);

      final historyJson =
          currentHistory.map((item) {
            return jsonEncode(item.toJson());
          }).toList();

      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      print('Error deleting history item: $e');
    }
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }
}
