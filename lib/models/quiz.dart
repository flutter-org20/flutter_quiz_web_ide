enum QuestionType { multipleChoice, trueFalse, fillInTheBlank }

class Question {
  final String id;
  final String questionText;
  final QuestionType type;
  final List<String> options; // For multiple choice
  final List<String> correctAnswers; // Can be multiple for checkbox-style MC
  final String? explanation;

  Question({
    required this.id,
    required this.questionText,
    required this.type,
    this.options = const [],
    required this.correctAnswers,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: (json['options'] as List<dynamic>?)?.cast<String>() ?? [],
      correctAnswers: (json['correctAnswers'] as List<dynamic>).cast<String>(),
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type.toString().split('.').last,
      'options': options,
      'correctAnswers': correctAnswers,
      'explanation': explanation,
    };
  }
}

class QuizAnswer {
  final String questionId;
  final List<String> selectedAnswers;
  final bool isCorrect;
  final DateTime answeredAt;

  QuizAnswer({
    required this.questionId,
    required this.selectedAnswers,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      questionId: json['questionId'] as String,
      selectedAnswers:
          (json['selectedAnswers'] as List<dynamic>).cast<String>(),
      isCorrect: json['isCorrect'] as bool,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswers': selectedAnswers,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }
}

class Quiz {
  final String id;
  final String title;
  final List<Question> questions;
  final List<QuizAnswer> answers;
  final DateTime createdAt;
  final int rollNumber;
  final bool isCompleted;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    this.answers = const [],
    required this.createdAt,
    required this.rollNumber,
    this.isCompleted = false,
  });

  double get score {
    if (questions.isEmpty) return 0.0;
    final correctAnswers = answers.where((answer) => answer.isCorrect).length;
    return (correctAnswers / questions.length) * 100;
  }

  Quiz copyWith({
    String? id,
    String? title,
    List<Question>? questions,
    List<QuizAnswer>? answers,
    DateTime? createdAt,
    int? rollNumber,
    bool? isCompleted,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
      rollNumber: rollNumber ?? this.rollNumber,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      questions:
          (json['questions'] as List<dynamic>)
              .map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList(),
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((a) => QuizAnswer.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      rollNumber: json['rollNumber'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      'answers': answers.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'rollNumber': rollNumber,
      'isCompleted': isCompleted,
    };
  }
}
