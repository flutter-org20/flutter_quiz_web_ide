import 'package:flutter/material.dart';
import '../models/quiz.dart';
import 'virtual_keyboard.dart';

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
        // Trigger rebuild to update the check icon color
        setState(() {});
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
        final bool isFillInBlank =
            widget.question.type == QuestionType.fillInTheBlank;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main question card
            Card(
              margin: EdgeInsets.all(constraints.maxWidth < 300 ? 4.0 : 8.0),
              child: Padding(
                padding: EdgeInsets.all(
                  constraints.maxWidth < 300 ? 12.0 : 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
              ),
            ),
            // Virtual keyboard - always show for fill-in-the-blank questions
            if (isFillInBlank && !widget.isAnswered) ...[
              const SizedBox(height: 8),
              IntrinsicHeight(
                child: VirtualKeyboard(controller: _textController),
              ),
            ],
          ],
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
        }),
      ],
    );
  }

  Widget _buildTrueFalse() {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

            return Flexible(
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

    // Determine check icon color based on text content
    final bool hasText = _textController.text.isNotEmpty;
    final Color checkIconColor = hasText ? Colors.green : Colors.grey;

    return Column(
      children: [
        TextFormField(
          controller: _textController,
          focusNode: _textFocus,
          enabled: !widget.isAnswered,
          decoration: InputDecoration(
            hintText: 'Type your answer using the keyboard below...',
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
            suffixIcon:
                !widget.isAnswered
                    ? Tooltip(
                      message: 'Answer saved',
                      triggerMode: TooltipTriggerMode.tap,
                      child: GestureDetector(
                        onTap:
                            hasText
                                ? () {
                                  // Tooltip will show automatically on tap due to TooltipTriggerMode.tap
                                  // The icon stays green after being tapped
                                }
                                : null,
                        child: Icon(Icons.check_circle, color: checkIconColor),
                      ),
                    )
                    : Icon(
                      Icons.check_circle,
                      color:
                          widget.showCorrectAnswer && widget.isAnswered
                              ? (borderColor == Colors.green
                                  ? Colors.green
                                  : Colors.red)
                              : Colors.grey[600],
                    ),
          ),
          onTap: () {
            // Keep focus for cursor positioning
            if (!widget.isAnswered) {
              _textFocus.requestFocus();
            }
          },
        ),
      ],
    );
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
