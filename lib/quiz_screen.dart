import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/quiz_service.dart';
import '../widgets/quiz_panel.dart';
import '../models/quiz.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();

  // Quiz management
  final Map<int, Quiz?> _quizzes = {};
  final Map<int, bool> _isGeneratingQuiz = {};

  // Student management
  int numberOfStudents = 1; // Default to 1 student
  final Map<int, int> _rollNumbers = {};
  final Set<int> _usedRollNumbers = {};
  final math.Random _random = math.Random();

  // UI state
  bool _isGenerating = false;
  String? _errorMessage;

  // Quiz generation settings
  String? _selectedTopic;
  String? _selectedDifficulty;
  int _questionCount = 5;

  @override
  void initState() {
    super.initState();
    _assignRollNumbers();
    _initializeQuizzes();
  }

  void _assignRollNumbers() {
    // Preserve existing roll numbers if they exist
    final existingRollNumbers = Map<int, int>.from(_rollNumbers);

    _rollNumbers.clear();
    _usedRollNumbers.clear();

    // First, restore existing roll numbers for students that still exist
    for (int i = 1; i <= numberOfStudents; i++) {
      if (existingRollNumbers.containsKey(i)) {
        _rollNumbers[i] = existingRollNumbers[i]!;
        _usedRollNumbers.add(existingRollNumbers[i]!);
      }
    }

    // Then assign new roll numbers for any missing students
    for (int i = 1; i <= numberOfStudents; i++) {
      if (!_rollNumbers.containsKey(i)) {
        int rollNumber;
        do {
          rollNumber = _random.nextInt(40) + 1; // 1-40
        } while (_usedRollNumbers.contains(rollNumber));

        _rollNumbers[i] = rollNumber;
        _usedRollNumbers.add(rollNumber);
      }
    }
  }

  void _refreshRollNumber(int studentNumber) {
    setState(() {
      // Remove the current roll number from used set
      _usedRollNumbers.remove(_rollNumbers[studentNumber]);

      // Generate a new unique roll number
      int newRollNumber;
      int attempts = 0;
      do {
        newRollNumber = _random.nextInt(40) + 1; // 1-40
        attempts++;
        // If all numbers are used (unlikely with 40 numbers for 4 students),
        // allow duplicates after 50 attempts
        if (attempts > 50) break;
      } while (_usedRollNumbers.contains(newRollNumber));

      // Update the roll number
      _rollNumbers[studentNumber] = newRollNumber;
      _usedRollNumbers.add(newRollNumber);
    });
  }

  void _updateStudentCount(int newCount) {
    setState(() {
      final oldCount = numberOfStudents;
      numberOfStudents = newCount;

      // If increasing student count, add new students
      if (newCount > oldCount) {
        for (int i = oldCount + 1; i <= newCount; i++) {
          _quizzes[i] = null;
          _isGeneratingQuiz[i] = false;
        }
        _assignRollNumbers(); // Reassign to include new students
      }
      // If decreasing student count, clean up removed students
      else if (newCount < oldCount) {
        for (int i = newCount + 1; i <= oldCount; i++) {
          _usedRollNumbers.remove(_rollNumbers[i]);
          _rollNumbers.remove(i);
          _quizzes.remove(i);
          _isGeneratingQuiz.remove(i);
        }
      }
    });
  }

  void _initializeQuizzes() {
    for (int i = 1; i <= numberOfStudents; i++) {
      _quizzes[i] = null;
      _isGeneratingQuiz[i] = false;
    }
  }

  Future<void> _generateNewQuizSet() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Generate quizzes for all students
      final futures = <Future<void>>[];
      for (int i = 1; i <= numberOfStudents; i++) {
        setState(() {
          _isGeneratingQuiz[i] = true;
        });
        futures.add(_generateQuizForStudent(i));
      }

      await Future.wait(futures);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate quizzes: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateQuizForStudent(int studentNumber) async {
    try {
      final quiz = await _quizService.generateQuiz(
        topic: _selectedTopic,
        difficulty: _selectedDifficulty,
        questionCount: _questionCount,
        rollNumber: _rollNumbers[studentNumber]!,
      );

      setState(() {
        _quizzes[studentNumber] = quiz;
        _isGeneratingQuiz[studentNumber] = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingQuiz[studentNumber] = false;
        _errorMessage =
            'Failed to generate quiz for student $studentNumber: $e';
      });
    }
  }

  void _onQuizUpdated(int studentNumber, Quiz updatedQuiz) {
    setState(() {
      _quizzes[studentNumber] = updatedQuiz;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          _buildHeader(),
          _buildGenerationBar(),
          if (_errorMessage != null) _buildErrorMessage(),
          Expanded(child: _buildQuizGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.quiz, size: 32, color: Colors.white),
          const SizedBox(width: 12),
          const Text(
            'AI Quiz Web App',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Student count selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Students:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: numberOfStudents,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  underline: Container(),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white70,
                  ),
                  items:
                      [1, 2, 3, 4].map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateStudentCount(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: const Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Use column layout on very small screens
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildTopicDropdown(),
                    const SizedBox(height: 12),
                    _buildDifficultyDropdown(),
                    const SizedBox(height: 12),
                    _buildQuestionCountField(),
                  ],
                );
              }
              // Use row layout on larger screens
              return Row(
                children: [
                  Expanded(flex: 2, child: _buildTopicDropdown()),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildDifficultyDropdown()),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: _buildQuestionCountField()),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateNewQuizSet,
                  icon:
                      _isGenerating
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate New Quiz Set',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _assignRollNumbers,
                  icon: const Icon(Icons.shuffle),
                  label: const Text(
                    'Shuffle Roll Numbers',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTopic,
      decoration: const InputDecoration(
        labelText: 'Topic',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Mixed Topics')),
        ..._quizService.getAvailableTopics().map(
          (topic) => DropdownMenuItem(value: topic, child: Text(topic)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedTopic = value;
        });
      },
    );
  }

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedDifficulty,
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Mixed Difficulty')),
        ..._quizService.getAvailableDifficulties().map(
          (difficulty) =>
              DropdownMenuItem(value: difficulty, child: Text(difficulty)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDifficulty = value;
        });
      },
    );
  }

  Widget _buildQuestionCountField() {
    return TextFormField(
      initialValue: _questionCount.toString(),
      decoration: const InputDecoration(
        labelText: 'Questions',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final count = int.tryParse(value);
        if (count != null && count > 0 && count <= 20) {
          _questionCount = count;
        }
      },
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.red[900],
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Handle single student case with centered layout
        if (numberOfStudents == 1) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Center(
              key: ValueKey('single-student'),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: constraints.maxHeight * 0.9,
                ),
                padding: const EdgeInsets.all(16.0),
                child: QuizPanel(
                  rollNumber: _rollNumbers[1]!,
                  panelNumber: 1,
                  quiz: _quizzes[1],
                  onQuizUpdated: (quiz) => _onQuizUpdated(1, quiz),
                  isLoading: _isGeneratingQuiz[1] ?? false,
                  onRollNumberRefresh: () => _refreshRollNumber(1),
                ),
              ),
            ),
          );
        }

        // Multiple students grid layout
        int crossAxisCount;
        double aspectRatio;

        if (constraints.maxWidth > 1400) {
          // Large desktop screens
          crossAxisCount = numberOfStudents == 4 ? 4 : numberOfStudents;
          aspectRatio = 0.85;
        } else if (constraints.maxWidth > 1000) {
          // Medium desktop screens
          crossAxisCount = numberOfStudents == 4 ? 4 : numberOfStudents;
          aspectRatio = 0.75;
        } else if (constraints.maxWidth > 700) {
          // Tablet landscape
          crossAxisCount = 2;
          aspectRatio = 0.8;
        } else if (constraints.maxWidth > 500) {
          // Tablet portrait
          crossAxisCount = 2;
          aspectRatio = 0.7;
        } else {
          // Mobile screens
          crossAxisCount = 1;
          aspectRatio = 0.6;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: GridView.builder(
            key: ValueKey('grid-$numberOfStudents'),
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: numberOfStudents,
            itemBuilder: (context, index) {
              final studentNumber = index + 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: QuizPanel(
                  rollNumber: _rollNumbers[studentNumber]!,
                  panelNumber: studentNumber,
                  quiz: _quizzes[studentNumber],
                  onQuizUpdated: (quiz) => _onQuizUpdated(studentNumber, quiz),
                  isLoading: _isGeneratingQuiz[studentNumber] ?? false,
                  onRollNumberRefresh: () => _refreshRollNumber(studentNumber),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
