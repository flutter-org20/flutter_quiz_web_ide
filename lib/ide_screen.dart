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
  String _output = '';
  final Map<String, String> _editorOutputs = {};
  bool _isLoading = false;
  final double _editorHeightRatio = 0.6;
  bool _pyodideLoaded = false;
  double _fontSize = 14.0;
  bool _showSpecialChars = false;
  final Map<String, String> _lastText = {};
  final Map<String, CodeHistory> _codeHistories = {};
  String _currentTheme = 'vs-dark';
  final Map<String, String> _currentFileNames = {};
  bool _preventHistoryUpdate = false;

  String? _currentRunningEditorId;
  int numberOfStudents = 4;
  final List<String> _monacoElementIds = [
    'monaco-editor-container-1',
    'monaco-editor-container-2',
    'monaco-editor-container-3',
    'monaco-editor-container-4',
  ];

  final List<String> _monacoDivIds = [
    'monaco-editor-div-1',
    'monaco-editor-div-2',
    'monaco-editor-div-3',
    'monaco-editor-div-4',
  ];
  bool _monacoInitialized = false;

  final List<String> _availableThemes = ['vs-dark', 'vs-light', 'hc-black'];

  @override
  void initState() {
    super.initState();

    // Initialize state for each editor
    for (final id in _monacoDivIds) {
      _codeHistories[id] = CodeHistory();
      _lastText[id] = '';
      _currentFileNames[id] = 'untitled.py';
      _editorOutputs[id] = '';
    }

    // Register editor views
    for (var i = 0; i < _monacoElementIds.length; i++) {
      ui_web.platformViewRegistry.registerViewFactory(
        _monacoElementIds[i],
        (int viewId) =>
            html.DivElement()
              ..id = _monacoDivIds[i]
              ..style.width = '100%'
              ..style.height = '100%',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reduced delay since DOM elements are now always present
      Future.delayed(const Duration(milliseconds: 500), () {
        _setupMonacoEditor();
      });
      _initializePyodide();
    });
  }

  Future<void> _initializePyodide() async {
    // Define the callback function for Python output
    void onOutput(String message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Add output to the active editor (you might want to track which editor is active)
            final activeEditorId =
                _currentRunningEditorId ??
                _monacoDivIds[0]; // or track active editor
            _editorOutputs[activeEditorId] =
                (_editorOutputs[activeEditorId] ?? '') + message;
          });
        }
      });
    }

    try {
      // Show a loading message in the output
      setState(() => _output = 'Initializing Python environment...\n');

      // Add timeout to prevent hanging
      String initMessage = await interop
          .initPyodide(onOutput)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Pyodide initialization timed out after 30 seconds',
              );
            },
          );

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

# Simple example
x = 2 + 3
print("Result:", x)

# Test function
def hello():
    return "Hello from Python!"

print(hello())
''';

    print('Setting up Monaco editors...'); // Debug log

    // Initialize all editors sequentially to avoid conflicts
    _initializeEditorsSequentially(initialCode);
  }

  Future<void> _initializeEditorsSequentially(String initialCode) async {
    // Shorter wait since DOM elements are now always present
    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < 4; i++) {
      final id = _monacoDivIds[i];
      _lastText[id] = initialCode;
      _codeHistories[id]?.addState(initialCode);

      // Check if DOM element exists before initializing
      print('Checking DOM element for $id...');

      try {
        // Wait for DOM element to be available with fewer retries since it should be there
        var retries = 0;
        while (retries < 10) {
          if (html.document.getElementById(id) != null) {
            print('DOM element found for $id, initializing...');
            break;
          }
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }

        if (retries >= 10) {
          print('DOM element $id not found after waiting ${retries * 100}ms');
          continue;
        }

        await interop.initMonaco(
          id,
          initialCode,
          _currentTheme,
          _fontSize,
          (content) => _onContentChanged(content, id),
        );
        print('Editor initialized: $id');

        // Delay between initializations
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (error) {
        print('Error initializing editor $id: $error');
      }
    }

    if (mounted) {
      setState(() => _monacoInitialized = true);
    }
  }

  Future<void> _cleanupEditors() async {
    for (int i = 0; i < 4; i++) {
      try {
        await interop.destroyEditor(_monacoDivIds[i]);
      } catch (error) {
        print('Error destroying editor ${_monacoDivIds[i]}: $error');
      }
    }
  }

  Future<void> _reinitializeEditors() async {
    setState(() {
      _monacoInitialized = false;
    });

    await _cleanupEditors();

    await Future.delayed(const Duration(milliseconds: 100));
    _setupMonacoEditor();
  }

  void _onContentChanged(String content, String editorId) {
    // Run in post-frame callback to avoid calling setState during a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_preventHistoryUpdate && content != _lastText[editorId]) {
        _codeHistories[editorId]?.addState(content);
        _lastText[editorId] = content;
        setState(() {}); // Update Undo/Redo button states
      }
    });
  }

  Future<void> _runCode([String? editorId]) async {
    final id = editorId ?? _monacoDivIds[0];

    // Guard against running before Pyodide is loaded
    if (!_pyodideLoaded) {
      _showSnackBar('Python environment is still initializing. Please wait.');
      return;
    }
    _currentRunningEditorId = id;

    setState(() {
      _editorOutputs[id] = '';
      _isLoading = true;
    });

    try {
      final code = interop.getMonacoValue(id);
      final String? error = await interop.runPyodideCode(code);

      if (error != null && mounted) {
        setState(
          () => _editorOutputs[id] = '${_editorOutputs[id] ?? ''}\n$error',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _editorOutputs[id] =
                  '${_editorOutputs[id] ?? ''}\nExecution error: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentRunningEditorId = null;
        });
      }
    }
  }

  void _updateMonacoWithHistory(String? newState, String editorId) {
    if (newState == null) return;
    _preventHistoryUpdate = true;
    setState(() {
      interop.setMonacoValue(editorId, newState);
      _lastText[editorId] = newState;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preventHistoryUpdate = false;
    });
  }

  void _undo([String? editorId]) {
    final id = editorId ?? _monacoDivIds[0];
    if (_codeHistories[id]?.canUndo() == true) {
      _updateMonacoWithHistory(_codeHistories[id]?.undo(), id);
      _showSnackBar('Undo successful');
    }
  }

  void _redo([String? editorId]) {
    final id = editorId ?? _monacoDivIds[0];
    if (_codeHistories[id]?.canRedo() == true) {
      _updateMonacoWithHistory(_codeHistories[id]?.redo(), id);
      _showSnackBar('Redo successful');
    }
  }

  void _clearOutput([String? editorId]) {
    if (editorId != null) {
      setState(() => _editorOutputs[editorId] = '');
    } else {
      // Clear all outputs if no specific editor is specified
      setState(() {
        for (final id in _monacoDivIds) {
          _editorOutputs[id] = '';
        }
      });
    }
  }

  void _updateMonacoSettings([String? editorId]) {
    if (editorId != null) {
      interop.updateMonacoOptions(editorId, _currentTheme, _fontSize);
    } else {
      for (final id in _monacoDivIds) {
        interop.updateMonacoOptions(id, _currentTheme, _fontSize);
      }
    }
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

  void _selectAll([String? editorId]) {
    if (editorId != null) {
      interop.selectAllInMonaco(editorId);
    } else {
      for (final id in _monacoDivIds) {
        interop.selectAllInMonaco(id);
      }
    }
    _showSnackBar('All text selected');
  }

  void _prettifyCode([String? editorId]) {
    if (editorId != null) {
      interop.formatMonacoDocument(editorId);
    } else {
      for (final id in _monacoDivIds) {
        interop.formatMonacoDocument(id);
      }
    }
    _showSnackBar('Code formatted');
  }

  void _insertSpecialChar(String char, [String? editorId]) {
    if (editorId != null) {
      interop.insertMonacoText(editorId, char);
    } else {
      for (final id in _monacoDivIds) {
        interop.insertMonacoText(id, char);
      }
    }
  }

  void _loadExample(String exampleName, [String? editorId]) {
    final exampleCode = CodeExamples.examples[exampleName];
    if (exampleCode != null) {
      if (editorId != null) {
        interop.setMonacoValue(editorId, exampleCode);
        _lastText[editorId] = exampleCode;
        _codeHistories[editorId]?.clear();
        _codeHistories[editorId]?.addState(exampleCode);
        final fileName = '${exampleName.toLowerCase().replaceAll(' ', '_')}.py';
        setState(() => _currentFileNames[editorId] = fileName);
      } else {
        // Load in all editors
        for (final id in _monacoDivIds) {
          interop.setMonacoValue(id, exampleCode);
          _lastText[id] = exampleCode;
          _codeHistories[id]?.clear();
          _codeHistories[id]?.addState(exampleCode);
          final fileName =
              '${exampleName.toLowerCase().replaceAll(' ', '_')}.py';
          _currentFileNames[id] = fileName;
        }
        setState(() {});
      }
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
                // Clear all editors
                for (final id in _monacoDivIds) {
                  interop.setMonacoValue(id, '');
                  _lastText[id] = '';
                  _codeHistories[id]?.clear();
                  _codeHistories[id]?.addState('');
                  _currentFileNames[id] = 'untitled.py';
                }
                setState(() {});
                Navigator.of(context).pop();
                _showSnackBar('Editors cleared');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _copyCode([String? editorId]) {
    final id = editorId ?? _monacoDivIds[0];
    interop.copyMonacoSelection(id);
    _showSnackBar('Code copied to clipboard');
  }

  void _pasteCode([String? editorId]) async {
    final id = editorId ?? _monacoDivIds[0];
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        interop.insertMonacoText(id, data.text!);
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

  void _saveCodeToFile([String? editorId]) {
    _showSaveDialog(editorId);
  }

  void _showSaveDialog([String? editorId]) {
    final id = editorId ?? _monacoDivIds[0];
    final TextEditingController fileNameController = TextEditingController(
      text: _currentFileNames[id] ?? 'untitled.py',
    );

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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String fileName = fileNameController.text.trim();
                if (fileName.isEmpty) fileName = 'untitled.py';
                if (!fileName.endsWith('.py')) fileName += '.py';

                _downloadFile(fileName, interop.getMonacoValue(id));
                setState(() => _currentFileNames[id] = fileName);
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
    final blob = html.Blob([content], 'text/plain');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
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
        title: Text(
          'Python Web IDE - $numberOfStudents Student${numberOfStudents == 1 ? '' : 's'}',
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) async {
              setState(() {
                numberOfStudents = value;
              });
              await _reinitializeEditors();
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<int>(
                    value: 0,
                    enabled: false,
                    child: Text(
                      'Number of Students',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const PopupMenuDivider(),
                  for (int i = 1; i <= 4; i++)
                    PopupMenuItem<int>(
                      value: i,
                      child: Row(
                        children: [
                          if (numberOfStudents == i)
                            const Icon(Icons.check, size: 16),
                          if (numberOfStudents == i) const SizedBox(width: 8),
                          Text('$i Student${i == 1 ? '' : 's'}'),
                        ],
                      ),
                    ),
                ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: 'Change Theme',
            onSelected: (value) {
              if (value != 'header') _changeTheme(value);
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'header',
                    enabled: false,
                    child: Text(
                      'Editor Themes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const PopupMenuDivider(),
                  ..._availableThemes.map(
                    (theme) =>
                        PopupMenuItem<String>(value: theme, child: Text(theme)),
                  ),
                ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.school),
            tooltip: 'Load Example',
            onSelected: (value) {
              if (value != 'header') _loadExample(value);
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'header',
                    enabled: false,
                    child: Text(
                      'Code Examples',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
            onRun: () => _runCode(_monacoDivIds[0]),
            fontSize: _fontSize,
            onSpecialCharInsert:
                (char) => _insertSpecialChar(char, _monacoDivIds[0]),
            onClear: () => _clearOutput(_monacoDivIds[0]),
            onClearEditor: () => _clearEditor(),
            onSelectAll: () => _selectAll(_monacoDivIds[0]),
            onCopy: () => _copyCode(_monacoDivIds[0]),
            onPaste: () => _pasteCode(_monacoDivIds[0]),
            onUndo: () => _undo(_monacoDivIds[0]),
            onRedo: () => _redo(_monacoDivIds[0]),
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onPrettify: () => _prettifyCode(_monacoDivIds[0]),
            onToggleSpecialChars: _toggleSpecialChars,
            canUndo: _codeHistories[_monacoDivIds[0]]?.canUndo() ?? false,
            canRedo: _codeHistories[_monacoDivIds[0]]?.canRedo() ?? false,
            showSpecialChars: _showSpecialChars,
          ),
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < numberOfStudents; i++)
                  Expanded(
                    child: Column(
                      children: [
                        // Editor section
                        Expanded(
                          flex: (_editorHeightRatio * 100).toInt(),
                          child: Stack(
                            children: [
                              HtmlElementView(viewType: _monacoElementIds[i]),
                              if (!_monacoInitialized)
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        // Output section
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
                                    const Icon(
                                      Icons.terminal,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Output ${i + 1}'),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed:
                                          () => _runCode(_monacoDivIds[i]),
                                      tooltip: 'Run Code',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed:
                                          () => _clearOutput(_monacoDivIds[i]),
                                      tooltip: 'Clear Output',
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.grey),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: SelectableText(
                                      _editorOutputs[_monacoDivIds[i]]
                                                  ?.isEmpty ??
                                              true
                                          ? 'Output will appear here...'
                                          : _editorOutputs[_monacoDivIds[i]] ??
                                              '',
                                      style: TextStyle(
                                        color:
                                            (_editorOutputs[_monacoDivIds[i]] ??
                                                        '')
                                                    .contains('Error')
                                                ? Colors.red
                                                : Colors.white,
                                        fontFamily: 'monospace',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isLoading)
                                  const LinearProgressIndicator(minHeight: 2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
