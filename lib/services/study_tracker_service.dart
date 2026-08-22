import 'package:shared_preferences/shared_preferences.dart';

class StudyTrackerService {
  static const String _keyPrefix = 'study_tracker_';
  static const String _streakKey = 'study_streak_count';
  static const String _lastStudyDateKey = 'study_last_date';
  static const String _dailyGoalMinutesKey = 'study_daily_goal_minutes';

  static String _getDateKey(DateTime date) {
    return '$_keyPrefix${date.year}_${date.month}_${date.day}';
  }

  // Record a completed study/pomodoro session in minutes
  static Future<void> addStudyMinutes(int minutes) async {
    if (minutes <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = _getDateKey(now);

    final currentMinutes = prefs.getInt(dateKey) ?? 0;
    await prefs.setInt(dateKey, currentMinutes + minutes);

    // Update total completed pomodoro cycles (if session >= 20 mins)
    final totalCycles = prefs.getInt('study_total_pomodoros') ?? 0;
    if (minutes >= 20) {
      await prefs.setInt('study_total_pomodoros', totalCycles + (minutes ~/ 25).clamp(1, 10));
    }

    // Update streak
    await _updateStreak(prefs, now);
  }

  // Record study seconds incrementally so partial sessions are never lost
  static Future<void> addStudySeconds(int seconds) async {
    if (seconds <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = _getDateKey(now);
    final secKey = '${dateKey}_accumulated_seconds';

    final totalSec = (prefs.getInt(secKey) ?? 0) + seconds;
    final minutesToAdd = totalSec ~/ 60;
    final remainingSec = totalSec % 60;

    await prefs.setInt(secKey, remainingSec);
    if (minutesToAdd > 0) {
      final currentMinutes = prefs.getInt(dateKey) ?? 0;
      await prefs.setInt(dateKey, currentMinutes + minutesToAdd);
      await _updateStreak(prefs, now);
    }
  }

  static Future<void> _updateStreak(SharedPreferences prefs, DateTime now) async {
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastDateStr = prefs.getString(_lastStudyDateKey);

    if (lastDateStr == todayStr) {
      // Already updated for today
      return;
    }

    int currentStreak = prefs.getInt(_streakKey) ?? 0;
    if (lastDateStr != null) {
      final parts = lastDateStr.split('-');
      if (parts.length == 3) {
        final lastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final differenceInDays = now.difference(lastDate).inDays;
        if (differenceInDays == 1) {
          currentStreak += 1;
        } else if (differenceInDays > 1) {
          currentStreak = 1;
        }
      }
    } else {
      currentStreak = 1;
    }

    await prefs.setInt(_streakKey, currentStreak);
    await prefs.setString(_lastStudyDateKey, todayStr);
  }

  // Get Today's study minutes
  static Future<int> getTodayStudyMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _getDateKey(DateTime.now());
    return prefs.getInt(dateKey) ?? 0;
  }

  // Get This Week's study minutes
  static Future<int> getThisWeekStudyMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      total += prefs.getInt(dateKey) ?? 0;
    }
    return total;
  }

  // Get Streak count
  static Future<int> getStreakDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 1;
  }

  // Get Total Pomodoro cycles count
  static Future<int> getTotalPomodoroCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('study_total_pomodoros') ?? 0;
  }

  // Get Daily Target Goal in Minutes (default 8 hours = 480 mins)
  static Future<int> getDailyGoalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalMinutesKey) ?? 480;
  }

  static Future<void> setDailyGoalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalMinutesKey, minutes);
  }

  static String formatMinutesToHours(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }
}