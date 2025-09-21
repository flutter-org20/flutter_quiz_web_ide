// Use the modern, built-in JS interop library
import 'dart:js_interop';

// --- Callback Type Definitions for your Dart code ---
typedef ContentChangedCallback = void Function(String content);
typedef PythonOutputCallback = void Function(String message);

// --- Monaco Interop Bindings ---

@JS('monacoInterop.init')
external JSPromise _initMonaco(
  String containerId,
  String initialCode,
  String theme,
  double fontSize,
  JSFunction onContentChanged,
);

// Public wrapper that handles the Dart-to-JS function conversion for you
Future<void> initMonaco(
  String containerId,
  String initialCode,
  String theme,
  double fontSize,
  ContentChangedCallback onContentChanged,
) async {
  try {
    // Add a check to ensure monacoInterop is available
    if (!_isMonacoInteropAvailable()) {
      throw Exception(
        'monacoInterop is not available. Make sure interop.js is loaded.',
      );
    }

    await _initMonaco(
      containerId,
      initialCode,
      theme,
      fontSize,
      onContentChanged.toJS,
    ).toDart;
  } catch (e) {
    print('Error initializing Monaco Editor: $e');
    rethrow;
  }
}

@JS('monacoInterop')
external JSObject? _monacoInteropObject;

bool _isMonacoInteropAvailable() {
  return _monacoInteropObject != null;
}

@JS('monacoInterop.getValue')
external JSString _getMonacoValue(String containerId);
String getMonacoValue(String containerId) =>
    _getMonacoValue(containerId).toDart;

@JS('monacoInterop.setValue')
external void setMonacoValue(String containerId, String content);

@JS('monacoInterop.updateOptions')
external void updateMonacoOptions(
  String containerId,
  String theme,
  double fontSize,
);

@JS('monacoInterop.formatDocument')
external void formatMonacoDocument(String containerId);

@JS('monacoInterop.selectAll')
external void selectAllInMonaco(String containerId);

@JS('monacoInterop.insertText')
external void insertMonacoText(String containerId, String text);

@JS('monacoInterop.copySelection')
external void copyMonacoSelection(String containerId);

// --- Pyodide Interop Bindings ---

@JS('pyodideInterop.init')
external JSPromise _initPyodide(JSFunction onOutput);

// Public wrapper that handles the Promise and function conversion
Future<String> initPyodide(PythonOutputCallback onOutput) {
  return _initPyodide(
    onOutput.toJS,
  ).toDart.then((value) => (value as JSString).toDart);
}

@JS('pyodideInterop.runCode')
external JSPromise _runPyodideCode(String code);

// Public wrapper that handles the Promise and converts nullable results
Future<String?> runPyodideCode(String code) {
  return _runPyodideCode(code).toDart.then((value) {
    return (value as JSString?)?.toDart;
  });
}

@JS('destroyMonacoEditor')
external void _destroyMonacoEditor(String elementId);

Future<void> destroyEditor(String elementId) async {
  try {
    _destroyMonacoEditor(elementId);
  } catch (e) {
    print('Failed to destroy editor $elementId: $e');
  }
}
