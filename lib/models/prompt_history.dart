class PromptHistoryItem {
  final String id;
  final String prompt;
  final DateTime timestamp;
  final List<String> responses;

  PromptHistoryItem({
    required this.id,
    required this.prompt,
    required this.timestamp,
    required this.responses,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'timestamp': timestamp.toIso8601String(),
      'responses': responses,
    };
  }

  factory PromptHistoryItem.fromJson(Map<String, dynamic> json) {
    return PromptHistoryItem(
      id: json['id'],
      prompt: json['prompt'],
      timestamp: DateTime.parse(json['timestamp']),
      responses: List<String>.from(json['responses'] ?? []),
    );
  }
}
