import 'package:flutter/material.dart';

class EditorWithOutput extends StatelessWidget {
  final String editorId;
  final String elementViewType;
  final String output;
  final bool isLoading;
  final VoidCallback onClearOutput;
  final VoidCallback onRun;
  final double editorHeightRatio;

  const EditorWithOutput({
    Key? key,
    required this.editorId,
    required this.elementViewType,
    required this.output,
    required this.isLoading,
    required this.onClearOutput,
    required this.onRun,
    this.editorHeightRatio = 0.6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Editor section
        Expanded(
          flex: (editorHeightRatio * 100).toInt(),
          child: HtmlElementView(viewType: elementViewType),
        ),
        const Divider(height: 1, color: Colors.grey),
        // Output section
        Expanded(
          flex: ((1 - editorHeightRatio) * 100).toInt(),
          child: Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Output'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: onRun,
                      tooltip: 'Run Code',
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearOutput,
                      tooltip: 'Clear Output',
                    ),
                  ],
                ),
                const Divider(color: Colors.grey),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      output.isEmpty ? 'Output will appear here...' : output,
                      style: TextStyle(
                        color:
                            output.contains('Error')
                                ? Colors.red
                                : Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (isLoading) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
