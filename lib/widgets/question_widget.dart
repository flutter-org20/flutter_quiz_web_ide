import 'package:flutter/material.dart';
import '../models/quiz.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final List<String> userAnswers;
  final Function(List<String>) onAnswerChanged;
  final bool showCorrectAnswer;
  final bool isAnswered;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.userAnswers,
    required this.onAnswerChanged,
    this.showCorrectAnswer = false,
    this.isAnswered = false,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  bool _showVirtualKeyboard = false;

  @override
  void initState() {
    super.initState();
    if (widget.question.type == QuestionType.fillInTheBlank &&
        widget.userAnswers.isNotEmpty) {
      _textController.text = widget.userAnswers.first;
    }

    _textController.addListener(() {
      if (widget.question.type == QuestionType.fillInTheBlank) {
        widget.onAnswerChanged([_textController.text]);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          margin: EdgeInsets.all(constraints.maxWidth < 300 ? 4.0 : 8.0),
          child: Padding(
            padding: EdgeInsets.all(constraints.maxWidth < 300 ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.question.questionText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildQuestionInput(),
                if (widget.showCorrectAnswer && widget.isAnswered) ...[
                  const SizedBox(height: 12),
                  _buildFeedback(),
                ],
                if (widget.question.type == QuestionType.fillInTheBlank &&
                    _showVirtualKeyboard) ...[
                  const SizedBox(height: 12),
                  _buildSimpleKeyboard(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionInput() {
    switch (widget.question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoice();
      case QuestionType.trueFalse:
        return _buildTrueFalse();
      case QuestionType.fillInTheBlank:
        return _buildFillInTheBlank();
    }
  }

  Widget _buildMultipleChoice() {
    final isMultipleAnswer = widget.question.correctAnswers.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMultipleAnswer)
          Text(
            'Select all correct answers:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey[400],
            ),
          ),
        const SizedBox(height: 8),
        ...widget.question.options.map((option) {
          final isSelected = widget.userAnswers.contains(option);
          final isCorrect = widget.question.correctAnswers.contains(option);

          Color? backgroundColor;
          Color? borderColor;

          if (widget.showCorrectAnswer && widget.isAnswered) {
            if (isCorrect) {
              backgroundColor = Colors.green.withOpacity(0.2);
              borderColor = Colors.green;
            } else if (isSelected && !isCorrect) {
              backgroundColor = Colors.red.withOpacity(0.2);
              borderColor = Colors.red;
            }
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              border:
                  borderColor != null ? Border.all(color: borderColor) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                isMultipleAnswer
                    ? CheckboxListTile(
                      title: Text(option),
                      value: isSelected,
                      onChanged:
                          widget.isAnswered
                              ? null
                              : (bool? value) {
                                final newAnswers = List<String>.from(
                                  widget.userAnswers,
                                );
                                if (value == true) {
                                  newAnswers.add(option);
                                } else {
                                  newAnswers.remove(option);
                                }
                                widget.onAnswerChanged(newAnswers);
                              },
                    )
                    : RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue:
                          widget.userAnswers.isNotEmpty
                              ? widget.userAnswers.first
                              : null,
                      onChanged:
                          widget.isAnswered
                              ? null
                              : (String? value) {
                                if (value != null) {
                                  widget.onAnswerChanged([value]);
                                }
                              },
                    ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTrueFalse() {
    return Row(
      children:
          widget.question.options.map((option) {
            final isSelected = widget.userAnswers.contains(option);
            final isCorrect = widget.question.correctAnswers.contains(option);

            Color? backgroundColor;
            Color? borderColor;

            if (widget.showCorrectAnswer && widget.isAnswered) {
              if (isCorrect) {
                backgroundColor = Colors.green.withOpacity(0.2);
                borderColor = Colors.green;
              } else if (isSelected && !isCorrect) {
                backgroundColor = Colors.red.withOpacity(0.2);
                borderColor = Colors.red;
              }
            }

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border:
                      borderColor != null
                          ? Border.all(color: borderColor)
                          : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue:
                      widget.userAnswers.isNotEmpty
                          ? widget.userAnswers.first
                          : null,
                  onChanged:
                      widget.isAnswered
                          ? null
                          : (String? value) {
                            if (value != null) {
                              widget.onAnswerChanged([value]);
                            }
                          },
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildFillInTheBlank() {
    Color? borderColor;
    Color? fillColor;

    if (widget.showCorrectAnswer && widget.isAnswered) {
      final isCorrect = widget.question.correctAnswers.any(
        (correct) =>
            correct.toLowerCase().trim() ==
            _textController.text.toLowerCase().trim(),
      );
      if (isCorrect) {
        borderColor = Colors.green;
        fillColor = Colors.green.withOpacity(0.1);
      } else {
        borderColor = Colors.red;
        fillColor = Colors.red.withOpacity(0.1);
      }
    }

    return Column(
      children: [
        TextFormField(
          controller: _textController,
          focusNode: _textFocus,
          enabled: !widget.isAnswered,
          decoration: InputDecoration(
            hintText: 'Enter your answer...',
            filled: fillColor != null,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor ?? Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor ?? Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? Theme.of(context).primaryColor,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showVirtualKeyboard ? Icons.keyboard_hide : Icons.keyboard,
              ),
              onPressed: () {
                setState(() {
                  _showVirtualKeyboard = !_showVirtualKeyboard;
                });
                if (_showVirtualKeyboard) {
                  _textFocus.unfocus();
                }
              },
            ),
          ),
          onTap: () {
            setState(() {
              _showVirtualKeyboard = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSimpleKeyboard() {
    const keys = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ...keys
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row.map((key) => _buildKey(key)).toList(),
                  ),
                ),
              )
              .toList(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKey('Space', isWide: true),
                _buildKey('⌫', isBackspace: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(
    String key, {
    bool isWide = false,
    bool isBackspace = false,
  }) {
    return Expanded(
      flex: isWide ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: ElevatedButton(
          onPressed: () => _handleKeyPress(key, isBackspace: isBackspace),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: const Size(0, 36),
          ),
          child: Text(
            key == 'Space' ? 'Space' : key,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _handleKeyPress(String key, {bool isBackspace = false}) {
    final currentText = _textController.text;
    final currentPosition = _textController.selection.start;

    if (isBackspace) {
      if (currentPosition > 0) {
        final newText =
            currentText.substring(0, currentPosition - 1) +
            currentText.substring(currentPosition);
        _textController.text = newText;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: currentPosition - 1),
        );
      }
    } else if (key == 'Space') {
      final newText =
          currentText.substring(0, currentPosition) +
          ' ' +
          currentText.substring(currentPosition);
      _textController.text = newText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: currentPosition + 1),
      );
    } else {
      final newText =
          currentText.substring(0, currentPosition) +
          key +
          currentText.substring(currentPosition);
      _textController.text = newText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: currentPosition + key.length),
      );
    }
  }

  Widget _buildFeedback() {
    final isCorrect = _isAnswerCorrect();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCorrect
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isCorrect ? Colors.green : Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              'Correct answer(s): ${widget.question.correctAnswers.join(', ')}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
          if (widget.question.explanation != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.question.explanation!,
              style: TextStyle(color: Colors.grey[300]),
            ),
          ],
        ],
      ),
    );
  }

  bool _isAnswerCorrect() {
    if (widget.userAnswers.isEmpty) return false;

    switch (widget.question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        final userSet = widget.userAnswers.toSet();
        final correctSet = widget.question.correctAnswers.toSet();
        return userSet.containsAll(correctSet) &&
            correctSet.containsAll(userSet);

      case QuestionType.fillInTheBlank:
        final userAnswer = widget.userAnswers.first.toLowerCase().trim();
        return widget.question.correctAnswers.any(
          (correct) => correct.toLowerCase().trim() == userAnswer,
        );
    }
  }
}
