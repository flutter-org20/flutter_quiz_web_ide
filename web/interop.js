// --- Globals ---
let monacoEditors = {}; // Object to store editor instances
let pyodide;
let monacoLoaded = false;
let monacoLoadPromise = null;

// Helper function to clean common invalid characters from code
function sanitizeCode(code) {
  // Replaces non-breaking spaces and other problematic characters
  return code.replace(/\u00A0/g, " ").replace(/\u2028/g, "\n").replace(/\u2029/g, "\n");
}

// --- Helper function to format code using Black in Pyodide ---
async function formatPythonCodeWithBlack(code) {
  if (!pyodide) {
    console.error("Pyodide not loaded, cannot format.");
    throw new Error("Pyodide not loaded");
  }

  const sanitizedCode = sanitizeCode(code);

  try {
    // Pass the code to the Python environment
    pyodide.globals.set("unformatted_code", sanitizedCode);

    // Let Pyodide handle exceptions. If this fails, the promise will reject
    // and be caught by the JavaScript 'catch' block.
    const formattedCode = await pyodide.runPythonAsync(`
import black

# Get the code from the global scope
source_code = unformatted_code

# Configure black's formatting mode
mode = black.FileMode(line_length=88, string_normalization=True)

# Format the string. This will raise an exception on invalid syntax.
black.format_str(source_code, mode=mode)
    `);

    return formattedCode;
  } catch (err) {
    // This will now catch Python exceptions directly!
    console.error("Error during Pyodide formatting execution:", err);
    throw err; // Re-throw to be caught by the Monaco format provider
  }
}

// Function to initialize Monaco only once
function loadMonaco() {
  if (!monacoLoadPromise) {
    monacoLoadPromise = new Promise((resolve) => {
      require.config({
        paths: { 'vs': 'https://unpkg.com/monaco-editor@0.41.0/min/vs' }
      });

      require(['vs/editor/editor.main'], () => {
        monacoLoaded = true;
        resolve();
      });
    });
  }
  return monacoLoadPromise;
}

console.log('Monaco Interop JavaScript loaded');

// --- Monaco Interop ---
window.monacoInterop = {
  init: async (containerId, initialCode, theme, fontSize, onContentChanged) => {
    console.log('Monaco init called for:', containerId);
    try {
      // Check if DOM element exists
      const container = document.getElementById(containerId);
      if (!container) {
        throw new Error(`DOM element with ID '${containerId}' not found`);
      }
      console.log('DOM element found for:', containerId);

      // Ensure Monaco is loaded first
      if (!monacoLoaded) {
        await loadMonaco();
      }

      const editor = monaco.editor.create(container, {
        value: initialCode,
        language: 'python',
        theme: theme,
        fontSize: fontSize,
        automaticLayout: true,
        formatOnPaste: true,
        formatOnType: false,
        wordWrap: 'on',
        minimap: { enabled: false },
        scrollBeyondLastLine: false,
        renderLineHighlight: 'line',
        selectOnLineNumbers: true
      });

      // Store the editor instance
      monacoEditors[containerId] = editor;

      // Set up content change listener
      editor.onDidChangeModelContent(() => {
        onContentChanged(editor.getValue());
      });

      return editor;
    } catch (error) {
      console.error('Error creating Monaco editor:', error);
      throw error;
    }
  },

  getValue: (containerId) => {
    const editor = monacoEditors[containerId];
    return editor ? editor.getValue() : '';
  },

  setValue: (containerId, content) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.setValue(content);
    }
  },

  updateOptions: (containerId, theme, fontSize) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.updateOptions({ theme, fontSize });
    }
  },

  formatDocument: (containerId) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.getAction('editor.action.formatDocument').run();
    }
  },

  selectAll: (containerId) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.setSelection(editor.getModel().getFullModelRange());
    }
  },

  insertText: (containerId, text) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.trigger('keyboard', 'type', { text });
    }
  },

  copySelection: (containerId) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      const selection = editor.getSelection();
      const text = editor.getModel().getValueInRange(selection);
      navigator.clipboard.writeText(text);
    }
  }
};

window.destroyMonacoEditor = function(elementId) {
  if(monacoEditors && monacoEditors[elementId]) {
    // Dispose the Monaco editor
    monacoEditors[elementId].dispose();
    delete monacoEditors[elementId];
    
    // Also clear the DOM container
    const container = document.getElementById(elementId);
    if (container) {
      container.innerHTML = '';
    }
  }
}

window.insertTextAtCursor = function(editorId, text) {
  const editor = monacoEditors[editorId];
  if (editor) {
    const selection = editor.getSelection();
    const range = new monaco.Range(
      selection.startLineNumber,
      selection.startColumn,
      selection.endLineNumber,
      selection.endColumn
    );
    editor.executeEdits('keyboard-input', [{
      range: range,
      text: text
    }]);
    editor.focus();
  }
};

window.deleteCharacterBeforeCursor = function(editorId) {
  const editor = monacoEditors[editorId];
  if (editor) {
    const position = editor.getPosition();
    if (position.column > 1) {
      const range = new monaco.Range(
        position.lineNumber,
        position.column - 1,
        position.lineNumber,
        position.column
      );
      editor.executeEdits('backspace', [{
        range: range,
        text: ''
      }]);
    } else if (position.lineNumber > 1) {
      // Handle backspace at beginning of line
      const model = editor.getModel();
      const prevLineLength = model.getLineLength(position.lineNumber - 1);
      const range = new monaco.Range(
        position.lineNumber - 1,
        prevLineLength + 1,
        position.lineNumber,
        1
      );
      editor.executeEdits('backspace', [{
        range: range,
        text: ''
      }]);
    }
    editor.focus();
  }
};

window.moveCursor = function(editorId, direction) {
  const editor = monacoEditors[editorId];
  if (editor) {
    const position = editor.getPosition();
    let newPosition;
    
    switch(direction) {
      case 'up':
        newPosition = { lineNumber: Math.max(1, position.lineNumber - 1), column: position.column };
        break;
      case 'down':
        const lineCount = editor.getModel().getLineCount();
        newPosition = { lineNumber: Math.min(lineCount, position.lineNumber + 1), column: position.column };
        break;
      case 'left':
        if (position.column > 1) {
          newPosition = { lineNumber: position.lineNumber, column: position.column - 1 };
        } else if (position.lineNumber > 1) {
          const prevLineLength = editor.getModel().getLineLength(position.lineNumber - 1);
          newPosition = { lineNumber: position.lineNumber - 1, column: prevLineLength + 1 };
        } else {
          newPosition = position;
        }
        break;
      case 'right':
        const currentLineLength = editor.getModel().getLineLength(position.lineNumber);
        if (position.column <= currentLineLength) {
          newPosition = { lineNumber: position.lineNumber, column: position.column + 1 };
        } else {
          const lineCount = editor.getModel().getLineCount();
          if (position.lineNumber < lineCount) {
            newPosition = { lineNumber: position.lineNumber + 1, column: 1 };
          } else {
            newPosition = position;
          }
        }
        break;
      default:
        newPosition = position;
    }
    
    editor.setPosition(newPosition);
    editor.focus();
  }
};
// --- Pyodide Interop ---
window.pyodideInterop = {
  init: (onOutput) => {
    return new Promise(async (resolve, reject) => {
      try {
        console.log('Loading Pyodide...');
        pyodide = await loadPyodide();
        
        // Set up proper output redirection using the modern Pyodide API
        pyodide.setStdout({
          batched: (text) => {
            console.log('Python output:', text);
            onOutput(text);
          }
        });
        
        pyodide.setStderr({
          batched: (text) => {
            console.error('Python error:', text);
            onOutput(text);
          }
        });

        console.log('Installing basic packages...');
        // Only load essential packages, skip black for now
        await pyodide.loadPackage(['micropip']);
        
        console.log('Pyodide ready for Python execution!');
        resolve('Pyodide initialized successfully!');
      } catch (err) {
        console.error('Error initializing Pyodide:', err);
        reject(err.toString());
      }
    });
  },

  runCode: async (code) => {
    if (!pyodide) {
      throw new Error('Pyodide not initialized');
    }

    try {
      await pyodide.runPythonAsync(code);
      return null; // No error
    } catch (err) {
      return err.message; // Return error message
    }
  }
};

console.log('monacoInterop object created:', window.monacoInterop);
console.log('pyodideInterop object created:', window.pyodideInterop);