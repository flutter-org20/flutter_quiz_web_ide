import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/quiz.dart';

class QuizService {
  static const String pollinationsBaseUrl = 'https://text.pollinations.ai';

  static const List<String> quizTopics = [
    'Science',
    'History',
    'Mathematics',
    'Literature',
    'Geography',
    'Technology',
    'Sports',
    'Art',
    'Music',
    'General Knowledge',
  ];

  static const List<String> difficultyLevels = ['Easy', 'Medium', 'Hard'];

  final Random _random = Random();

  /// Generate a quiz using pollinations.ai
  Future<Quiz> generateQuiz({
    String? topic,
    String? difficulty,
    int questionCount = 5,
    required int rollNumber,
  }) async {
    try {
      final selectedTopic =
          topic ?? quizTopics[_random.nextInt(quizTopics.length)];
      final selectedDifficulty =
          difficulty ??
          difficultyLevels[_random.nextInt(difficultyLevels.length)];

      final prompt =
          '''Generate a quiz with exactly $questionCount questions about $selectedTopic at $selectedDifficulty difficulty level.

Format the response as a valid JSON object with this exact structure:
{
  "title": "Quiz Title",
  "questions": [
    {
      "id": "q1",
      "questionText": "Question text here?",
      "type": "multipleChoice",
      "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
      "correctAnswers": ["Option 1"],
      "explanation": "Brief explanation of the correct answer"
    },
    {
      "id": "q2", 
      "questionText": "True or false question?",
      "type": "trueFalse",
      "options": ["True", "False"],
      "correctAnswers": ["True"],
      "explanation": "Brief explanation"
    },
    {
      "id": "q3",
      "questionText": "Fill in the blank: The capital of France is ___.",
      "type": "fillInTheBlank", 
      "options": [],
      "correctAnswers": ["Paris"],
      "explanation": "Brief explanation"
    }
  ]
}

Requirements:
- Mix question types: multiple choice (can have multiple correct answers), true/false, and fill-in-the-blank
- Each question must have a unique id (q1, q2, q3, etc.)
- For multiple choice: provide 4 options and mark correct ones in correctAnswers array
- For true/false: options are ["True", "False"] and correctAnswers contains the right choice
- For fill-in-the-blank: options is empty array, correctAnswers contains accepted answers
- Include brief explanations for all answers
- Make questions engaging and educational
- Response must be valid JSON only, no additional text''';

      final response = await http.post(
        Uri.parse(pollinationsBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'model': 'openai',
        }),
      );

      if (response.statusCode == 200) {
        final responseText = response.body.trim();

        // Try to extract JSON from the response
        String jsonString = responseText;

        // If response is wrapped in markdown code blocks, extract the JSON
        if (responseText.contains('```json')) {
          final start = responseText.indexOf('```json') + 7;
          final end = responseText.lastIndexOf('```');
          if (end > start) {
            jsonString = responseText.substring(start, end).trim();
          }
        } else if (responseText.contains('```')) {
          final start = responseText.indexOf('```') + 3;
          final end = responseText.lastIndexOf('```');
          if (end > start) {
            jsonString = responseText.substring(start, end).trim();
          }
        }

        try {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

          final questions =
              (jsonData['questions'] as List<dynamic>)
                  .map((q) => Question.fromJson(q as Map<String, dynamic>))
                  .toList();

          return Quiz(
            id: _generateId(),
            title: jsonData['title'] as String? ?? '$selectedTopic Quiz',
            questions: questions,
            createdAt: DateTime.now(),
            rollNumber: rollNumber,
          );
        } catch (e) {
          print('Error parsing AI response JSON: $e');
          print('Response was: $responseText');
          // Return a fallback quiz
          return _createFallbackQuiz(selectedTopic, rollNumber);
        }
      } else {
        print('Error from pollinations.ai: ${response.statusCode}');
        print('Response: ${response.body}');
        return _createFallbackQuiz(topic ?? 'General Knowledge', rollNumber);
      }
    } catch (e) {
      print('Error generating quiz: $e');
      return _createFallbackQuiz(topic ?? 'General Knowledge', rollNumber);
    }
  }

  /// Create a fallback quiz when AI generation fails
  Quiz _createFallbackQuiz(String topic, int rollNumber) {
    final questions = [
      Question(
        id: 'q1',
        questionText: 'What is the capital of France?',
        type: QuestionType.multipleChoice,
        options: ['London', 'Berlin', 'Paris', 'Madrid'],
        correctAnswers: ['Paris'],
        explanation: 'Paris is the capital and largest city of France.',
      ),
      Question(
        id: 'q2',
        questionText: 'The Earth is flat.',
        type: QuestionType.trueFalse,
        options: ['True', 'False'],
        correctAnswers: ['False'],
        explanation: 'The Earth is approximately spherical in shape.',
      ),
      Question(
        id: 'q3',
        questionText:
            'Fill in the blank: The largest planet in our solar system is ___.',
        type: QuestionType.fillInTheBlank,
        options: [],
        correctAnswers: ['Jupiter'],
        explanation: 'Jupiter is the largest planet in our solar system.',
      ),
      Question(
        id: 'q4',
        questionText:
            'Which of the following are programming languages? (Select all that apply)',
        type: QuestionType.multipleChoice,
        options: ['Python', 'HTML', 'Java', 'CSS'],
        correctAnswers: ['Python', 'Java'],
        explanation:
            'Python and Java are programming languages. HTML and CSS are markup/styling languages.',
      ),
      Question(
        id: 'q5',
        questionText: 'Water boils at 100 degrees Celsius at sea level.',
        type: QuestionType.trueFalse,
        options: ['True', 'False'],
        correctAnswers: ['True'],
        explanation:
            'At standard atmospheric pressure (sea level), water boils at 100°C.',
      ),
    ];

    return Quiz(
      id: _generateId(),
      title: '$topic Sample Quiz',
      questions: questions,
      createdAt: DateTime.now(),
      rollNumber: rollNumber,
    );
  }

  /// Generate a unique ID for quizzes
  String _generateId() {
    return 'quiz_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  /// Validate answer for a specific question
  bool validateAnswer(Question question, List<String> userAnswers) {
    if (userAnswers.isEmpty) return false;

    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        // For multiple choice, check if all correct answers are selected
        // and no incorrect answers are selected
        final userSet = userAnswers.toSet();
        final correctSet = question.correctAnswers.toSet();
        return userSet.containsAll(correctSet) &&
            correctSet.containsAll(userSet);

      case QuestionType.fillInTheBlank:
        // For fill-in-the-blank, check if any of the user's answers match
        // any of the correct answers (case-insensitive)
        final userAnswer = userAnswers.first.toLowerCase().trim();
        return question.correctAnswers.any(
          (correct) => correct.toLowerCase().trim() == userAnswer,
        );
    }
  }

  /// Get available quiz topics
  List<String> getAvailableTopics() {
    return List.from(quizTopics);
  }

  /// Get available difficulty levels
  List<String> getAvailableDifficulties() {
    return List.from(difficultyLevels);
  }
}
