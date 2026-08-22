import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/study_tracker_service.dart';

enum PomodoroMode { focus, shortBreak, longBreak }

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) => const PomodoroPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ColoredBox(
            color: const Color(0xFF0B0F19),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> with TickerProviderStateMixin {
  PomodoroMode _mode = PomodoroMode.focus;
  final int _focusDurationMinutes = 25;
  final int _shortBreakMinutes = 5;
  final int _longBreakMinutes = 15;

  late int _remainingSeconds;
  late int _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;
  int _completedCycles = 0;
  int _todayTotalMinutes = 0;
  int _unsavedFocusSeconds = 0;

  final List<String> _quotes = [
    "Focus on the process, and the results will take care of themselves.",
    "Small daily improvements over time lead to stunning results.",
    "Your future is created by what you do today, not tomorrow.",
    "Stay disciplined. The pain of discipline is far less than the pain of regret.",
    "Deep work is the superpower of the 21st century.",
    "Consistency is what transforms average into excellence."
  ];
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _setMode(PomodoroMode.focus);
    _loadTodayStats();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flushUnsavedTime();
    super.dispose();
  }

  Future<void> _loadTodayStats() async {
    final mins = await StudyTrackerService.getTodayStudyMinutes();
    final cycles = await StudyTrackerService.getTotalPomodoroCount();
    if (mounted) {
      setState(() {
        _todayTotalMinutes = mins;
        _completedCycles = cycles % 4;
      });
    }
  }

  Future<void> _flushUnsavedTime() async {
    if (_unsavedFocusSeconds > 0) {
      final secsToSave = _unsavedFocusSeconds;
      _unsavedFocusSeconds = 0;
      await StudyTrackerService.addStudySeconds(secsToSave);
      await _loadTodayStats();
    }
  }

  void _setMode(PomodoroMode mode) {
    _timer?.cancel();
    _flushUnsavedTime();
    setState(() {
      _mode = mode;
      _isRunning = false;
      switch (mode) {
        case PomodoroMode.focus:
          _totalSeconds = _focusDurationMinutes * 60;
          break;
        case PomodoroMode.shortBreak:
          _totalSeconds = _shortBreakMinutes * 60;
          break;
        case PomodoroMode.longBreak:
          _totalSeconds = _longBreakMinutes * 60;
          break;
      }
      _remainingSeconds = _totalSeconds;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      _flushUnsavedTime();
      HapticFeedback.lightImpact();
    } else {
      setState(() => _isRunning = true);
      HapticFeedback.mediumImpact();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
            if (_mode == PomodoroMode.focus) {
              _unsavedFocusSeconds++;
            }
          });
          // Flush every 15 seconds to ensure recorded time is updated in real time
          if (_unsavedFocusSeconds >= 15) {
            _flushUnsavedTime();
          }
        } else {
          _onTimerComplete();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _flushUnsavedTime();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    HapticFeedback.heavyImpact();

    if (_mode == PomodoroMode.focus) {
      // Flush remaining seconds and increment completed cycle count
      await _flushUnsavedTime();
      final currentCycles = await StudyTrackerService.getTotalPomodoroCount();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('study_total_pomodoros', currentCycles + 1);
      await _loadTodayStats();

      if (!mounted) return;
      _showCompletionDialog(
        title: 'Focus Session Completed! 🎯',
        message: 'Great job! You completed $_focusDurationMinutes minutes of deep study. Time for a well-deserved break.',
        nextMode: (_completedCycles + 1 >= 4) ? PomodoroMode.longBreak : PomodoroMode.shortBreak,
      );
    } else {
      if (!mounted) return;
      _showCompletionDialog(
        title: 'Break Finished! ⚡',
        message: 'Feeling refreshed? Let\'s jump back into deep focus mode.',
        nextMode: PomodoroMode.focus,
      );
    }
  }

  void _showCompletionDialog({
    required String title,
    required String message,
    required PomodoroMode nextMode,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey.shade300, fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _setMode(nextMode);
              _toggleTimer();
            },
            child: Text(
              nextMode == PomodoroMode.focus ? 'Start Focus' : 'Start Break',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? (1.0 - (_remainingSeconds / _totalSeconds)) : 0.0;
    final accentColor = _mode == PomodoroMode.focus
        ? const Color(0xFF6366F1) // Indigo
        : (_mode == PomodoroMode.shortBreak
            ? const Color(0xFF10B981) // Emerald Green
            : const Color(0xFF06B6D4)); // Cyan

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0B0F19),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          _flushUnsavedTime();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0F19), // Deep OLED Slate
          body: SafeArea(
            child: Column(
            children: [
              // Top Bar: Back/Minimize & Today Total
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        _flushUnsavedTime();
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 6),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Today: ${StudyTrackerService.formatMinutesToHours(_todayTotalMinutes)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Mode Selector Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildModeTab('Focus', PomodoroMode.focus, const Color(0xFF6366F1)),
                  _buildModeTab('Short Break', PomodoroMode.shortBreak, const Color(0xFF10B981)),
                  _buildModeTab('Long Break', PomodoroMode.longBreak, const Color(0xFF06B6D4)),
                ],
              ),
            ),

            const Spacer(),

            // Circular Countdown Timer
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow / Track
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_remainingSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 54,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mode == PomodoroMode.focus
                            ? 'DEEP FOCUS'
                            : (_mode == PomodoroMode.shortBreak ? 'SHORT BREAK' : 'LONG REST'),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Cycle Indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (index) {
                          final isDone = index < _completedCycles;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? accentColor : Colors.white.withValues(alpha: 0.15),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Action Controls: Pause/Play & Reset
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                IconButton.filledTonal(
                  iconSize: 24,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _resetTimer,
                  tooltip: 'Reset Timer',
                ),

                const SizedBox(width: 24),

                // Main Play/Pause Button
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: accentColor.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 38,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Skip / Next Button
                IconButton.filledTonal(
                  iconSize: 24,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_mode == PomodoroMode.focus) {
                      _setMode(PomodoroMode.shortBreak);
                    } else {
                      _setMode(PomodoroMode.focus);
                    }
                  },
                  tooltip: 'Skip to Next',
                ),
              ],
            ),

            const Spacer(),

            // Motivational Quote Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _quoteIndex = (_quoteIndex + 1) % _quotes.length;
                  });
                },
                child: Text(
                  '"${_quotes[_quoteIndex]}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildModeTab(String title, PomodoroMode mode, Color activeColor) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade400,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}