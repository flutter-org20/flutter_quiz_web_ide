// Use the modern, built-in JS interop library
import 'dart:js_interop';

// --- Callback Type Definitions for your Dart code ---
typedef ContentChangedCallback = void Function(String content);
typedef PythonOutputCallback = void Function(String message);


// --- Monaco Interop Bindings ---

// Note: The @JS annotation now comes from 'dart:js_interop'
@JS('monacoInterop.init')
// Private external function using the new JS types
external void _initMonaco(String containerId, String initialCode, String theme,
    double fontSize, JSFunction onContentChanged);

// Public wrapper that handles the Dart-to-JS function conversion for you
void initMonaco(String containerId, String initialCode, String theme,
    double fontSize, ContentChangedCallback onContentChanged) {
  _initMonaco(
      containerId, initialCode, theme, fontSize, onContentChanged.toJS);
}

@JS('monacoInterop.getValue')
external JSString _getMonacoValue();
String getMonacoValue() => _getMonacoValue().toDart;

@JS('monacoInterop.setValue')
external void setMonacoValue(String content);

@JS('monacoInterop.updateOptions')
external void updateMonacoOptions(String theme, double fontSize);

@JS('monacoInterop.formatDocument')
external void formatMonacoDocument();

@JS('monacoInterop.selectAll')
external void selectAllInMonaco();

@JS('monacoInterop.insertText')
external void insertMonacoText(String text);

@JS('monacoInterop.copySelection')
external void copyMonacoSelection();


// --- Pyodide Interop Bindings ---

@JS('pyodideInterop.init')
// Private external function returning a JSPromise
external JSPromise _initPyodide(JSFunction onOutput);

// Public wrapper that handles the Promise and function conversion
Future<String> initPyodide(PythonOutputCallback onOutput) {
  // Convert the JSPromise to a Dart Future and the result to a Dart String
  return _initPyodide(onOutput.toJS)
      .toDart
      .then((value) => (value as JSString).toDart);
}

@JS('pyodideInterop.runCode')
// Private external function returning a JSPromise
external JSPromise _runPyodideCode(String code);

// Public wrapper that handles the Promise and converts nullable results
Future<String?> runPyodideCode(String code) async {
  final promise = _runPyodideCode(code);
  final result = await promise.toDart; // result is a JSObject?
  // Use dartify to safely convert JS null/undefined/String to a Dart String?
  return result?.dartify() as String?;
}
