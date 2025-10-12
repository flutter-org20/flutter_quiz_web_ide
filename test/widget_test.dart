import 'package:flutter_test/flutter_test.dart';

import 'package:quiz_web_app/main.dart';

void main() {
  testWidgets('Quiz app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuizWebApp());

    // Verify that our app starts with the quiz screen
    expect(find.text('AI Quiz Web App'), findsOneWidget);
    expect(find.text('Generate New Quiz Set'), findsOneWidget);
  });
}
