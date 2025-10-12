import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../widgets/question_widget.dart';
import '../services/quiz_service.dart';

class QuizPanel extends StatefulWidget {
  final int rollNumber;
  final int panelNumber;
  final Quiz? quiz;
  final Function(Quiz) onQuizUpdated;
  final bool isLoading;
  final VoidCallback? onRollNumberRefresh;

  const QuizPanel({
    super.key,
    required this.rollNumber,
    required this.panelNumber,
    this.quiz,
    required this.onQuizUpdated,
    this.isLoading = false,
    this.onRollNumberRefresh,
  });

  @override
  State<QuizPanel> createState() => _QuizPanelState();
}

class _QuizPanelState extends State<QuizPanel> {
  final Map<String, List<String>> _userAnswers = {};
  final QuizService _quizService = QuizService();
  bool _showAnswers = false;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnswers();
  }

  @override
  void didUpdateWidget(QuizPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quiz != oldWidget.quiz) {
      _initializeAnswers();
      _showAnswers = false;
      _currentQuestionIndex = 0;
    }
  }

  void _initializeAnswers() {
    _userAnswers.clear();
    if (widget.quiz != null) {
      for (final question in widget.quiz!.questions) {
        _userAnswers[question.id] = [];
      }
      // Load existing answers if any
      for (final answer in widget.quiz!.answers) {
        _userAnswers[answer.questionId] = answer.selectedAnswers;
      }
    }
  }

  void _submitAnswer(String questionId, List<String> answers) {
    setState(() {
      _userAnswers[questionId] = answers;
    });
  }

  void _submitQuiz() {
    if (widget.quiz == null) return;

    final answers = <QuizAnswer>[];
    for (final question in widget.quiz!.questions) {
      final userAnswer = _userAnswers[question.id] ?? [];
      final isCorrect = _quizService.validateAnswer(question, userAnswer);

      answers.add(
        QuizAnswer(
          questionId: question.id,
          selectedAnswers: userAnswer,
          isCorrect: isCorrect,
          answeredAt: DateTime.now(),
        ),
      );
    }

    final updatedQuiz = widget.quiz!.copyWith(
      answers: answers,
      isCompleted: true,
    );

    widget.onQuizUpdated(updatedQuiz);
    setState(() {
      _showAnswers = true;
    });
  }

  void _resetQuiz() {
    setState(() {
      _showAnswers = false;
      _currentQuestionIndex = 0;
      _initializeAnswers();
    });

    if (widget.quiz != null) {
      final resetQuiz = widget.quiz!.copyWith(answers: [], isCompleted: false);
      widget.onQuizUpdated(resetQuiz);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          margin: EdgeInsets.all(constraints.maxWidth < 400 ? 4.0 : 8.0),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child:
                    widget.isLoading
                        ? _buildLoadingIndicator()
                        : widget.quiz == null
                        ? _buildEmptyState()
                        : _buildQuizContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz, color: Colors.blue[400]),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Quiz ${widget.panelNumber} - Roll No: ${widget.rollNumber}',
                key: ValueKey(widget.rollNumber), // Key for animation
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Roll number refresh button
          if (widget.onRollNumberRefresh != null)
            Tooltip(
              message: 'Refresh Roll Number',
              child: IconButton(
                icon: Icon(Icons.refresh, color: Colors.grey[400], size: 18),
                onPressed: widget.onRollNumberRefresh,
                splashRadius: 16,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          if (widget.quiz != null && widget.quiz!.isCompleted) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle, color: Colors.green[400]),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Score: ${widget.quiz!.score.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.green[400],
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating quiz questions...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No quiz loaded',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Generate a new quiz to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    if (widget.quiz!.questions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (widget.quiz!.questions.length > 1) _buildQuestionNavigation(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.quiz!.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                QuestionWidget(
                  question: widget.quiz!.questions[_currentQuestionIndex],
                  userAnswers:
                      _userAnswers[widget
                          .quiz!
                          .questions[_currentQuestionIndex]
                          .id] ??
                      [],
                  onAnswerChanged:
                      (answers) => _submitAnswer(
                        widget.quiz!.questions[_currentQuestionIndex].id,
                        answers,
                      ),
                  showCorrectAnswer: _showAnswers,
                  isAnswered: widget.quiz!.isCompleted,
                ),
              ],
            ),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildQuestionNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: const Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Question ${_currentQuestionIndex + 1} of ${widget.quiz!.questions.length}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed:
                _currentQuestionIndex > 0
                    ? () => setState(() => _currentQuestionIndex--)
                    : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.quiz!.questions.length, (index) {
                  final hasAnswer =
                      _userAnswers[widget.quiz!.questions[index].id]
                          ?.isNotEmpty ??
                      false;
                  return GestureDetector(
                    onTap: () => setState(() => _currentQuestionIndex = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            index == _currentQuestionIndex
                                ? Colors.blue[600]
                                : hasAnswer
                                ? Colors.green[600]
                                : Colors.grey[600],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          IconButton(
            onPressed:
                _currentQuestionIndex < widget.quiz!.questions.length - 1
                    ? () => setState(() => _currentQuestionIndex++)
                    : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: const Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          if (!widget.quiz!.isCompleted) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _hasAllAnswers() ? _submitQuiz : null,
                icon: const Icon(Icons.send),
                label: const Text('Submit Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetQuiz,
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasAllAnswers() {
    if (widget.quiz == null) return false;

    for (final question in widget.quiz!.questions) {
      final answers = _userAnswers[question.id];
      if (answers == null || answers.isEmpty) {
        return false;
      }
    }
    return true;
  }
}
