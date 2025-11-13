import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FaceStorage {
  static const String _keyEmbedding = 'face_embedding';

  // Save face embedding
  static Future<void> saveEmbedding(List<double> embedding) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(embedding);
      await prefs.setString(_keyEmbedding, jsonString);
      print('✅ Face embedding saved (${embedding.length} dimensions)');
    } catch (e) {
      print('Error saving embedding: $e');
    }
  }

  // Load face embedding
  static Future<List<double>?> loadEmbedding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyEmbedding);
      
      if (jsonString == null) return null;

      final List<dynamic> decoded = jsonDecode(jsonString);
      final embedding = decoded.map((e) => e as double).toList();
      
      print('✅ Face embedding loaded (${embedding.length} dimensions)');
      return embedding;
    } catch (e) {
      print('Error loading embedding: $e');
      return null;
    }
  }

  // Check if embedding exists
  static Future<bool> hasEmbedding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyEmbedding);
    } catch (e) {
      print('Error checking embedding: $e');
      return false;
    }
  }

  // Clear embedding
  static Future<void> clearEmbedding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyEmbedding);
      print('🗑️ Face embedding cleared');
    } catch (e) {
      print('Error clearing embedding: $e');
    }
  }
}
