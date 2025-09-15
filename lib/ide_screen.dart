import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/python.dart';
import './widgets/toolbar.dart';

void main() {
  runApp(const PythonWebIDE());
}

class CodeHistory {
  final List<String> _history = [];
  int _currentIndex = -1;

  void addState(String state) {
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    _history.add(state);
    _currentIndex++;

    if (_history.length > 50) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  String? undo() {
    if (canUndo()) {
      _currentIndex--;
      return _history[_currentIndex];
    }
    return null;
  }

  String? redo() {
    if (canRedo()) {
      _currentIndex++;
      return _history[_currentIndex];
    }
    return null;
  }

  bool canUndo() => _currentIndex > 0;
  bool canRedo() => _currentIndex < _history.length - 1;

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}

class PythonWebIDE extends StatelessWidget {
  const PythonWebIDE({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Web IDE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const IDEScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CodeExamples {
  static const Map<String, String> examples = {
    'Hello World': '''
print("Hello, World!")
''',
    'Fibonacci Sequence': '''
def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        print(a, end=' ')
        a, b = b, a + b
    print()

fibonacci(10)
''',
    'Math Operations': '''
import math

# Basic arithmetic
result = 10 + 5 * 2
print(f"10 + 5 * 2 = {result}")

# Math functions
print(f"Square root of 16: {math.sqrt(16)}")
print(f"Pi: {math.pi}")
''',
    'List Operations': '''
# List creation and manipulation
numbers = [1, 2, 3, 4, 5]
print(f"Original list: {numbers}")

# List comprehension
squares = [x**2 for x in numbers]
print(f"Squares: {squares}")

# Filter even numbers
evens = [x for x in numbers if x % 2 == 0]
print(f"Even numbers: {evens}")
''',
    'File I/O Simulation': '''
# Simulating file operations
def write_file(filename, content):
    print(f"Writing to {filename}:")
    print(content)
    return f"Written {len(content)} characters to {filename}"

def read_file(filename):
    content = f"This is simulated content of {filename}"
    print(f"Reading from {filename}:")
    print(content)
    return content

# Example usage
write_file("example.txt", "Hello, this is a test file!")
read_file("example.txt")
''',
    'Class Example': '''
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def introduce(self):
        return f"Hi, I'm {self.name} and I'm {self.age} years old."
    
    def have_birthday(self):
        self.age += 1
        return f"Happy Birthday! Now I'm {self.age} years old."

# Create a person instance
john = Person("John", 25)
print(john.introduce())
print(john.have_birthday())
''',
    'Data Structures': '''
# Dictionary operations
student = {
    "name": "Alice",
    "age": 20,
    "courses": ["Math", "Physics", "Chemistry"]
}

print("Student data:")
for key, value in student.items():
    print(f"{key}: {value}")

# Set operations
set_a = {1, 2, 3, 4, 5}
set_b = {4, 5, 6, 7, 8}

print(f"Union: {set_a | set_b}")
print(f"Intersection: {set_a & set_b}")
print(f"Difference: {set_a - set_b}")
''',
  };
}

class IDEScreen extends StatefulWidget {
  const IDEScreen({super.key});

  @override
  State<IDEScreen> createState() => _IDEScreenState();
}

class _IDEScreenState extends State<IDEScreen> {
  late CodeController _codeController;
  late CodeHistory _codeHistory;
  String _output = '';
  bool _isLoading = false;
  final double _editorHeightRatio = 0.6;
  bool _pyodideLoaded = false;
  double _fontSize = 14.0;
  bool _showSpecialChars = false;
  bool _isAllSelected = false;
  String _lastText = '';
  String _currentTheme = 'monokai';
  String _currentFileName = 'untitled.py';

  // ✅ Fixed: Ensure type is Map<String, TextStyle>
  final Map<String, Map<String, TextStyle>> _themes = {
    'monokai': monokaiSublimeTheme,
    'atom-dark': atomOneDarkTheme,
    'github': githubTheme,
    'vs2015': vs2015Theme,
  };

  @override
  void initState() {
    super.initState();
    _codeHistory = CodeHistory();
    _initializeCodeController();
    _initializePyodide();
  }

  void _initializeCodeController() {
    const initialCode = '''# Welcome to Python Web IDE!
# Write your Python code here

def hello_world():
    print("Hello, World!")
    return "Python is running in your browser!"

result = hello_world()
print(f"Result: {result}")
''';

    _codeController = CodeController(
      text: initialCode,
      language: python,
      // ✅ removed wrong theme parameter
    );
    _lastText = initialCode;
    _codeHistory.addState(initialCode);

    _codeController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isCurrentlyAllSelected =
        _codeController.selection.baseOffset == 0 &&
        _codeController.selection.extentOffset == _codeController.text.length;

    if (isCurrentlyAllSelected != _isAllSelected) {
      setState(() {
        _isAllSelected = isCurrentlyAllSelected;
      });
    }

    if (_codeController.text != _lastText) {
      _codeHistory.addState(_codeController.text);
      _lastText = _codeController.text;
      setState(() {});
    }
  }

  void _initializePyodide() {
    js.context.callMethod('eval', [
      '''
    window.updateOutput = function(message) {
      if (window.flutterOutputPort) {
        window.flutterOutputPort(message);
      }
    };
  ''',
    ]);

    js.context['flutterOutputPort'] = (String message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _output += '$message\n';
        });
      });
    };

    js.context.callMethod('eval', [
      r'''
    if (typeof window.pyodide === 'undefined') {
      window.pyodidePromise = new Promise((resolve) => {
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/pyodide.js';
        script.onload = async () => {
          window.pyodide = await loadPyodide({
            indexURL: 'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/'
          });

          window.pyodide.runPython(`
import sys
import js

class OutputCatcher:
    def write(self, message):
        js.updateOutput(message)
    def flush(self):
        pass

sys.stdout = OutputCatcher()
sys.stderr = OutputCatcher()
          `);

          resolve(window.pyodide);
        };
        document.head.appendChild(script);
      });
    }
  ''',
    ]);
  }

  Future<void> _runCode() async {
    if (!_pyodideLoaded) {
      setState(() {
        _output = 'Loading Pyodide... Please wait.';
        _isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _pyodideLoaded = true;
      });
    }

    setState(() {
      _output = '';
      _isLoading = true;
    });

    final code = _codeController.text;

    try {
      final result = await js.context.callMethod('eval', [
        '''
(async function() {
  try {
    if (!window.pyodide) {
      await window.pyodidePromise;
    }
    await window.pyodide.runPythonAsync(`$code`);
    return "Execution completed successfully";
  } catch (error) {
    return "Error: " + error.toString();
  }
})()
''',
      ]);

      if (result != null && result.toString().contains('Error')) {
        setState(() {
          _output += result.toString();
        });
      }
    } catch (e) {
      setState(() {
        _output += 'Execution error: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  void _clearOutput() => setState(() => _output = '');

  void _loadExample(String exampleName) {
    final exampleCode = CodeExamples.examples[exampleName];
    if (exampleCode != null) {
      setState(() {
        _codeController.text = exampleCode;
        _lastText = exampleCode;
        _codeHistory.addState(exampleCode);
        _currentFileName =
            '${exampleName.toLowerCase().replaceAll(' ', '_')}.py';
      });
    }
  }

  void _resetCode() {
    const resetCode = '''# Welcome to Python Web IDE!
print("Hello, Python!")''';
    setState(() {
      _codeController.text = resetCode;
      _lastText = resetCode;
      _output = '';
      _codeHistory.clear();
      _codeHistory.addState(resetCode);
      _currentFileName = 'untitled.py';
    });
  }

  void _selectAll() {
    _codeController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _codeController.text.length,
    );
    setState(() => _isAllSelected = true);
    _showSnackBar('All text selected');
  }

  void _copyCode() {
    String textToCopy = _codeController.selection.textInside(
      _codeController.text,
    );
    if (textToCopy.isEmpty) textToCopy = _codeController.text;
    Clipboard.setData(ClipboardData(text: textToCopy));
    _showSnackBar('Code copied to clipboard');
  }

  void _pasteCode() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null) {
      int start = _codeController.selection.baseOffset;
      int end = _codeController.selection.extentOffset;
      String newText = _codeController.text.replaceRange(
        start,
        end,
        data.text ?? '',
      );
      _codeController.text = newText;
      _codeController.selection = TextSelection.collapsed(
        offset: start + (data.text?.length ?? 0),
      );
      _lastText = newText;
      _codeHistory.addState(newText);
      _showSnackBar('Code pasted from clipboard');
    }
  }

  void _undo() {
    final previousState = _codeHistory.undo();
    if (previousState != null) {
      setState(() {
        _codeController.text = previousState;
        _lastText = previousState;
        _isAllSelected = false;
      });
      _showSnackBar('Undo successful');
    }
  }

  void _redo() {
    final nextState = _codeHistory.redo();
    if (nextState != null) {
      setState(() {
        _codeController.text = nextState;
        _lastText = nextState;
        _isAllSelected = false;
      });
      _showSnackBar('Redo successful');
    }
  }

  void _zoomIn() =>
      setState(() => _fontSize = (_fontSize + 2).clamp(8.0, 32.0));
  void _zoomOut() =>
      setState(() => _fontSize = (_fontSize - 2).clamp(8.0, 32.0));

  void _prettifyCode() {
    List<String> lines = _codeController.text.split('\n');
    List<String> formatted = [];
    int indent = 0;

    for (var line in lines) {
      String trimmed = line.trim();

      if (trimmed.isEmpty) {
        formatted.add('');
        continue;
      }

      if (trimmed.startsWith('except') ||
          trimmed.startsWith('elif') ||
          trimmed.startsWith('else') ||
          trimmed.startsWith('finally')) {
        indent = (indent - 1).clamp(0, 100);
      }

      formatted.add('    ' * indent + trimmed);

      if (trimmed.endsWith(':')) indent++;
    }

    final formattedCode = formatted.join('\n');
    setState(() {
      _codeController.text = formattedCode;
      _lastText = formattedCode;
      _codeHistory.addState(formattedCode);
    });
    _showSnackBar('Code formatted');
  }

  void _toggleSpecialChars() {
    setState(() => _showSpecialChars = !_showSpecialChars);
    _showSnackBar(
      _showSpecialChars
          ? 'Special characters shown'
          : 'Special characters hidden',
    );
  }

  void _insertSpecialChar(String char) {
    int pos = _codeController.selection.baseOffset;
    String text = _codeController.text;
    String newText = text.substring(0, pos) + char + text.substring(pos);

    _codeController.text = newText;
    _codeController.selection = TextSelection.collapsed(
      offset: pos + char.length,
    );
    _lastText = newText;
    _codeHistory.addState(newText);
  }

  void _changeTheme(String themeName) {
    setState(() {
      _currentTheme = themeName;
      _codeController = CodeController(
        text: _codeController.text,
        language: python,
      );
      _codeController.addListener(_onTextChanged);
    });
    _showSnackBar('Theme changed to $_currentTheme');
  }

  void _saveCodeToFile() {
    _showSaveDialog();
  }

  void _showSaveDialog() {
    final TextEditingController fileNameController = TextEditingController(
      text: _currentFileName,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Python File'),
          backgroundColor: Colors.grey[800],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fileNameController,
                decoration: const InputDecoration(
                  labelText: 'File name',
                  hintText: 'Enter file name with .py extension',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'This will download the file to your browser\'s default download folder.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String fileName = fileNameController.text.trim();
                if (fileName.isEmpty) {
                  fileName = 'untitled.py';
                } else if (!fileName.endsWith('.py')) {
                  fileName += '.py';
                }
                _downloadFile(fileName, _codeController.text);
                setState(() {
                  _currentFileName = fileName;
                });
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
    js.context.callMethod('eval', [
      '''
      (function() {
        var blob = new Blob(['$content'], {type: 'text/plain'});
        var url = window.URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.style.display = 'none';
        a.href = url;
        a.download = '$fileName';
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      })();
      ''',
    ]);
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
  void dispose() {
    _codeController.removeListener(_onTextChanged);
    _codeController.dispose();
    super.dispose();
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
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'header',
                    child: Text(
                      'Syntax Themes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const PopupMenuDivider(),
                  ..._themes.keys.map(
                    (theme) => PopupMenuItem<String>(
                      value: theme,
                      child: Row(
                        children: [
                          Icon(
                            _currentTheme == theme
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(theme),
                        ],
                      ),
                    ),
                  ),
                ],
            onSelected: (value) {
              if (value != 'header') {
                _changeTheme(value);
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.school),
            tooltip: 'Load Example',
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'header',
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
            onSelected: (value) {
              if (value != 'header') {
                _loadExample(value);
              }
            },
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
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  CodeTheme(
                    data: CodeThemeData(styles: _themes[_currentTheme]!),
                    child: CodeField(
                      controller: _codeController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _fontSize,
                      ),
                      lineNumberStyle: const LineNumberStyle(
                        textStyle: TextStyle(color: Colors.grey),
                        margin: 8,
                      ),
                    ),
                  ),
                ],
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
                          color:
                              _output.contains('Error')
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
