import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  Future<Set<String>> loadSolved() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(AppConstants.solvedKey) ?? [];
    return list.toSet();
  }

  Future<void> saveSolved(Set<String> solved) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.solvedKey, solved.toList());
  }

  Future<int> loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.scoreKey) ?? 0;
  }

  Future<void> saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.scoreKey, score);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.solvedKey);
    await prefs.remove(AppConstants.scoreKey);
  }
}
