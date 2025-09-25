class PollinationsResponse {
  final String text;
  final bool success;
  final String? error;

  PollinationsResponse({required this.text, this.success = true, this.error});

  factory PollinationsResponse.fromJson(Map<String, dynamic> json) {
    return PollinationsResponse(
      text: json['text'] ?? '',
      success: json['success'] ?? true,
      error: json['error'],
    );
  }

  factory PollinationsResponse.error(String error) {
    return PollinationsResponse(text: '', success: false, error: error);
  }
}
