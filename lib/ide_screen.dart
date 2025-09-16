import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import './widgets/toolbar.dart';
import 'interop.dart' as interop;
import 'utils/code_examples.dart';
import 'utils/code_history.dart';

class IDEScreen extends StatefulWidget {
  const IDEScreen({super.key});

  @override
  State<IDEScreen> createState() => _IDEScreenState();
}

class _IDEScreenState extends State<IDEScreen> {
  late CodeHistory _codeHistory;
  String _output = '';
  bool _isLoading = false;
  final double _editorHeightRatio = 0.6;
  bool _pyodideLoaded = false;
  double _fontSize = 14.0;
  bool _showSpecialChars = false;
  String _lastText = '';
  String _currentTheme = 'vs-dark';
  String _currentFileName = 'untitled.py';
  bool _preventHistoryUpdate = false;
  final String _monacoElementId = 'monaco-editor-container';
  final String _monacoDivId = 'monaco-editor-div'; // Static ID for the div
  bool _monacoInitialized = false;

  final List<String> _availableThemes = ['vs-dark', 'vs-light', 'hc-black'];

  @override
  void initState() {
    super.initState();
    _codeHistory = CodeHistory();

    // Use the prefix from dart:ui_web to access the registry
    ui_web.platformViewRegistry.registerViewFactory(
      _monacoElementId,
          (int viewId) => html.DivElement()
        ..id = _monacoDivId
        ..style.width = '100%'
        ..style.height = '100%',
    );

    // This part remains the same
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMonacoEditor();
      _initializePyodide();
    });
  }

  Future<void> _initializePyodide() async {
    // Define the callback function for Python output
    void onOutput(String message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _output += message);
        }
      });
    }

    try {
      // Show a loading message in the output
      setState(() => _output = 'Initializing Python environment...\n');
      String initMessage = await interop.initPyodide(onOutput);

      // Update the UI with the success message
      if (mounted) {
        setState(() {
          _output += '$initMessage\n\n';
          _pyodideLoaded = true; // Set the flag!
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _output += 'Error initializing Pyodide: $e\n');
      }
    }
  }

  void _setupMonacoEditor() {
    const initialCode = '''# Welcome to Python Web IDE!
# Write your Python code here and click Run.

def greet(name):
    print(f"Hello, {name}!")

greet("World")
''';
    _lastText = initialCode;
    _codeHistory.addState(initialCode);

    interop.initMonaco(
      _monacoDivId,
      initialCode,
      _currentTheme,
      _fontSize,
      _onContentChanged, // <-- Pass the function directly
    );

    setState(() => _monacoInitialized = true);
  }

  void _onContentChanged(String content) {
    // Run in post-frame callback to avoid calling setState during a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_preventHistoryUpdate && content != _lastText) {
        _codeHistory.addState(content);
        _lastText = content;
        setState(() {}); // Update Undo/Redo button states
      }
    });
  }

  // In lib/src/ide_screen.dart, inside _IDEScreenState

  Future<void> _runCode() async {
    // Guard against running before Pyodide is loaded
    if (!_pyodideLoaded) {
      _showSnackBar('Python environment is still initializing. Please wait.');
      return;
    }

    setState(() {
      _output = ''; // Clear previous output
      _isLoading = true;
    });

    try {
      final code = interop.getMonacoValue();
      final String? error = await interop.runPyodideCode(code);

      if (error != null && mounted) {
        setState(() => _output += '\n$error');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _output += '\nExecution error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMonacoWithHistory(String? newState) {
    if (newState == null) return;
    _preventHistoryUpdate = true;
    setState(() {
      interop.setMonacoValue(newState);
      _lastText = newState;
    });
    // Use a post-frame callback to ensure the update has been processed by Monaco
    // before re-enabling history tracking.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preventHistoryUpdate = false;
    });
  }

  void _undo() {
    if (_codeHistory.canUndo()) {
      _updateMonacoWithHistory(_codeHistory.undo());
      _showSnackBar('Undo successful');
    }
  }

  void _redo() {
    if (_codeHistory.canRedo()) {
      _updateMonacoWithHistory(_codeHistory.redo());
      _showSnackBar('Redo successful');
    }
  }

  void _clearOutput() => setState(() => _output = '');

  void _updateMonacoSettings() {
    interop.updateMonacoOptions(_currentTheme, _fontSize);
  }

  void _zoomIn() {
    setState(() {
      _fontSize = (_fontSize + 2).clamp(8.0, 32.0);
      _updateMonacoSettings();
    });
  }

  void _zoomOut() {
    setState(() {
      _fontSize = (_fontSize - 2).clamp(8.0, 32.0);
      _updateMonacoSettings();
    });
  }

  void _selectAll() {
    interop.selectAllInMonaco();
    _showSnackBar('All text selected');
  }

  void _prettifyCode() {
    interop.formatMonacoDocument();
    _showSnackBar('Code formatted');
  }

  void _insertSpecialChar(String char) => interop.insertMonacoText(char);

  void _loadExample(String exampleName) {
    final exampleCode = CodeExamples.examples[exampleName];
    if (exampleCode != null) {
      interop.setMonacoValue(exampleCode);
      _lastText = exampleCode;
      _codeHistory.clear();
      _codeHistory.addState(exampleCode);
      setState(() =>
      _currentFileName = '${exampleName.toLowerCase().replaceAll(' ', '_')}.py');
    }
  }

  void _clearEditor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Editor'),
          backgroundColor: Colors.grey[800],
          content: const Text(
            'Are you sure you want to clear all editor content? This action cannot be undone.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                interop.setMonacoValue('');
                _lastText = '';
                _codeHistory.clear();
                _codeHistory.addState('');
                setState(() {
                  _currentFileName = 'untitled.py';
                });
                Navigator.of(context).pop();
                _showSnackBar('Editor cleared');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _copyCode() {
    interop.copyMonacoSelection();
    _showSnackBar('Code copied to clipboard');
  }

  void _pasteCode() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        interop.insertMonacoText(data.text!);
        _showSnackBar('Code pasted from clipboard');
      }
    } catch (e) {
      log('Error pasting: $e');
    }
  }

  void _changeTheme(String themeName) {
    setState(() {
      _currentTheme = themeName;
      _updateMonacoSettings();
    });
    _showSnackBar('Theme changed to $_currentTheme');
  }

  void _toggleSpecialChars() {
    setState(() => _showSpecialChars = !_showSpecialChars);
    _showSnackBar(
      _showSpecialChars
          ? 'Special characters shown'
          : 'Special characters hidden',
    );
  }

  void _saveCodeToFile() {
    _showSaveDialog();
  }

  void _showSaveDialog() {
    final TextEditingController fileNameController =
    TextEditingController(text: _currentFileName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Python File'),
          backgroundColor: Colors.grey[800],
          content: TextField(
            controller: fileNameController,
            decoration: const InputDecoration(
              labelText: 'File name',
              hintText: 'Enter file name with .py extension',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                String fileName = fileNameController.text.trim();
                if (fileName.isEmpty) fileName = 'untitled.py';
                if (!fileName.endsWith('.py')) fileName += '.py';

                _downloadFile(fileName, interop.getMonacoValue());
                setState(() => _currentFileName = fileName);
                Navigator.of(context).pop();
                _showSnackBar('File saved as $fileName');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _downloadFile(String fileName, String content) {
    // This can be done with a JS interop call for more robustness,
    // but the original dart:html approach works well here.
    final blob = html.Blob([content], 'text/plain');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Python Web IDE - $_currentFileName'),
        backgroundColor: Colors.grey[900],
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: 'Change Theme',
            onSelected: (value) {
              if (value != 'header') _changeTheme(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'header',
                enabled: false,
                child: Text('Editor Themes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuDivider(),
              ..._availableThemes.map(
                    (theme) => PopupMenuItem<String>(
                  value: theme,
                  child: Text(theme),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.school),
            tooltip: 'Load Example',
            onSelected: (value) {
              if (value != 'header') _loadExample(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'header',
                enabled: false,
                child: Text('Code Examples', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuDivider(),
              ...CodeExamples.examples.keys.map(
                    (example) => PopupMenuItem<String>(
                  value: example,
                  child: Text(example),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save File',
            onPressed: _saveCodeToFile,
          ),
        ],
      ),
      body: Column(
        children: [
          ToolBar(
            onRun: _runCode,
            fontSize: _fontSize,
            onSpecialCharInsert: _insertSpecialChar,
            onClear: _clearOutput,
            onClearEditor: _clearEditor,
            onSelectAll: _selectAll,
            onCopy: _copyCode,
            onPaste: _pasteCode,
            onUndo: _undo,
            onRedo: _redo,
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onPrettify: _prettifyCode,
            onToggleSpecialChars: _toggleSpecialChars,
            canUndo: _codeHistory.canUndo(),
            canRedo: _codeHistory.canRedo(),
            showSpecialChars: _showSpecialChars,
          ),
          Expanded(
            flex: (_editorHeightRatio * 100).toInt(),
            child: Container(
              color: Colors.black,
              child: _monacoInitialized
                  ? HtmlElementView(viewType: _monacoElementId)
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading Editor...'),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            flex: ((1 - _editorHeightRatio) * 100).toInt(),
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
                        icon: const Icon(Icons.clear),
                        onPressed: _clearOutput,
                        tooltip: 'Clear Output',
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _output.isEmpty
                            ? 'Output will appear here...'
                            : _output,
                        style: TextStyle(
                          color: _output.contains('Error')
                              ? Colors.red
                              : Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
