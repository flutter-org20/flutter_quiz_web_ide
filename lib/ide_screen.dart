import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/python.dart';

void main() {
  runApp(const PythonWebIDE());
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
  String _output = '';
  bool _isLoading = false;
  double _editorHeightRatio = 0.6;
  bool _pyodideLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeCodeController();
    _initializePyodide();
  }

  void _initializeCodeController() {
    _codeController = CodeController(
      text: '''# Welcome to Python Web IDE!
# Write your Python code here

def hello_world():
    print("Hello, World!")
    return "Python is running in your browser!"

result = hello_world()
print(f"Result: {result}")

# Try some calculations
x = 10
y = 20
print(f"{x} + {y} = {x + y}")

# List comprehension example
squares = [i**2 for i in range(1, 6)]
print(f"Squares: {squares}")
''',
      language: python,
    );
  }

  void _initializePyodide() {
    // Load Pyodide from CDN
    js.context.callMethod('eval', [
      '''
      if (typeof window.pyodide === 'undefined') {
        window.pyodidePromise = new Promise((resolve) => {
          const script = document.createElement('script');
          script.src = 'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/pyodide.js';
          script.onload = async () => {
            window.pyodide = await loadPyodide({
              indexURL: 'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/'
            });
            
            // Override Python's print function
            window.pyodide.runPython(`
              import sys
              import js
              
              def custom_print(*args, **kwargs):
                  message = ' '.join(str(arg) for arg in args)
                  js.globalContext.callMethod('updateOutput', [message])
                  # Keep original print for console
                  original_print = getattr(sys.stdout, 'write', lambda x: None)
                  original_print(message + '\\\\n')
              
              # Replace built-in print
              builtins = pyodide.pyimport('builtins')
              builtins.print = custom_print
            `);
            
            resolve(window.pyodide);
          };
          document.head.appendChild(script);
        });
      }
      ''',
    ]);

    // Set up output callback
    js.context['updateOutput'] = (String message) {
      setState(() {
        _output += '$message\n';
      });
    };
  }

  Future<void> _runCode() async {
    if (!_pyodideLoaded) {
      setState(() {
        _output = 'Loading Pyodide... Please wait.';
        _isLoading = true;
      });

      // Wait for Pyodide to load
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
            await window.pyodide.runPythonAsync(`${_escapeJsString(code)}`);
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

  String _escapeJsString(String input) {
    return input
        .replaceAll(r'$', r'\$')
        .replaceAll('`', r'\`')
        //.replaceAll('\'', r'\'')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n');
  }

  void _clearOutput() {
    setState(() {
      _output = '';
    });
  }

  void _loadExample(String exampleName) {
    final exampleCode = CodeExamples.examples[exampleName];
    if (exampleCode != null) {
      setState(() {
        _codeController.text = exampleCode;
      });
    }
  }

  void _resetCode() {
    setState(() {
      _codeController.text = '''# Welcome to Python Web IDE!
# Write your Python code here

print("Hello, Python!")''';
      _output = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Python Web IDE'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _runCode,
            tooltip: 'Run Code',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearOutput,
            tooltip: 'Clear Output',
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetCode,
            tooltip: 'Reset Code',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_book),
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
                  ...CodeExamples.examples.keys
                      .map(
                        (key) =>
                            PopupMenuItem<String>(value: key, child: Text(key)),
                      )
                      .toList(),
                ],
            onSelected: (value) {
              if (value != 'header') {
                _loadExample(value);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: (_editorHeightRatio * 10).round(),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(8),
              child: CodeField(
                controller: _codeController,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                lineNumberStyle: const LineNumberStyle(
                  textStyle: TextStyle(color: Colors.grey),
                  margin: 8,
                ),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _editorHeightRatio -=
                      details.delta.dy / MediaQuery.of(context).size.height;
                  _editorHeightRatio = _editorHeightRatio.clamp(0.2, 0.8);
                });
              },
              child: Container(
                height: 8,
                color: Colors.grey[800],
                child: Center(
                  child: Container(
                    height: 2,
                    width: 50,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: ((1 - _editorHeightRatio) * 10).round(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Output:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _output.isEmpty
                            ? 'Output will appear here...\n\nTip: Use print() statements to see results.'
                            : _output,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runCode,
        tooltip: 'Run Python Code',
        backgroundColor: Colors.green,
        child: const Icon(Icons.play_arrow, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
