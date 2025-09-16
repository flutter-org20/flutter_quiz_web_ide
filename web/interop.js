// --- Globals ---
let monacoEditor;
let pyodide;

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

// --- Monaco Interop ---
window.monacoInterop = {
  init: (containerId, initialCode, theme, fontSize, onContentChanged) => {
    return new Promise((resolve, reject) => {
      require.config({
        paths: { 'vs': 'https://unpkg.com/monaco-editor@0.41.0/min/vs' }
      });

      require(['vs/editor/editor.main'], () => {
        try {
          monacoEditor = monaco.editor.create(document.getElementById(containerId), {
            value: initialCode,
            language: 'python',
            theme: theme,
            fontSize: fontSize,
            automaticLayout: true,
            formatOnPaste: true,
            formatOnType: false, // Disable auto-format on type for better performance
            wordWrap: 'on',
            minimap: { enabled: false },
            scrollBeyondLastLine: false,
            renderLineHighlight: 'line',
            selectOnLineNumbers: true
          });

          // Set up content change listener
          monacoEditor.onDidChangeModelContent(() => {
            onContentChanged(monacoEditor.getValue());
          });

          // Register the Python formatter
          const disposable = monaco.languages.registerDocumentFormattingEditProvider('python', {
            async provideDocumentFormattingEdits(model, options, token) {
              try {
                console.log('Formatting document...');
                const originalCode = model.getValue();
                console.log('Original code length:', originalCode.length);

                // Check if Pyodide is ready
                if (!pyodide) {
                  console.error('Pyodide not available for formatting');
                  return [];
                }

                const formattedCode = await formatPythonCodeWithBlack(originalCode);
                console.log('Formatted code length:', formattedCode.length);

                if (formattedCode !== originalCode) {
                  console.log('Code was formatted, applying changes');
                  return [{
                    range: model.getFullModelRange(),
                    text: formattedCode,
                  }];
                }
                console.log('No formatting changes needed');
                return []; // No changes needed
              } catch (error) {
                console.error('Formatting error details:', error.message || error);
                console.error('Full error object:', error);
                return []; // Return empty array on error
              }
            }
          });

          // Store the disposable for cleanup if needed
          monacoEditor._formatterDisposable = disposable;

          console.log('Monaco Editor initialized successfully');
          resolve();
        } catch (error) {
          console.error('Error initializing Monaco Editor:', error);
          reject(error);
        }
      }, (error) => {
        console.error('Error loading Monaco Editor modules:', error);
        reject(error);
      });
    });
  },

  formatDocument: async () => {
    if (!monacoEditor) {
      console.error('Monaco Editor not initialized');
      return false;
    }

    try {
      console.log('Triggering format document action...');
      await monacoEditor.getAction('editor.action.formatDocument').run();
      return true;
    } catch (error) {
      console.error('Error formatting document:', error);
      return false;
    }
  },

  // Alternative manual formatting method
  formatDocumentManually: async () => {
    if (!monacoEditor) {
      console.error('Monaco Editor not initialized');
      return false;
    }

    try {
      const originalCode = monacoEditor.getValue();
      console.log('Manual formatting...', originalCode.length, 'characters');
      const formattedCode = await formatPythonCodeWithBlack(originalCode);

      if (formattedCode !== originalCode) {
        monacoEditor.setValue(formattedCode);
        console.log('Code formatted successfully');
        return true;
      } else {
        console.log('No formatting changes needed');
        return true;
      }
    } catch (error) {
      console.error('Error in manual formatting:', error);
      return false;
    }
  },

  getValue: () => monacoEditor?.getValue() || '',

  setValue: (content) => {
    if (monacoEditor) {
      monacoEditor.setValue(sanitizeCode(content));
    }
  },

  updateOptions: (theme, fontSize) => {
    if (monacoEditor) {
      monacoEditor.updateOptions({ theme, fontSize });
    }
  },

  selectAll: () => {
    if (monacoEditor) {
      monacoEditor.getAction('editor.action.selectAll').run();
    }
  },

  insertText: (text) => {
    if (monacoEditor) {
      const sanitizedText = sanitizeCode(text);
      monacoEditor.executeEdits('paste', [{
        range: monacoEditor.getSelection(),
        text: sanitizedText,
      }]);
    }
  },

  copySelection: () => {
    if (monacoEditor) {
      const selection = monacoEditor.getModel().getValueInRange(monacoEditor.getSelection());
      if (selection && navigator.clipboard) {
        navigator.clipboard.writeText(selection);
      }
    }
  },

  // Utility methods for debugging
  isReady: () => !!monacoEditor,
  getModel: () => monacoEditor?.getModel(),

  // Method to check if formatting is available
  canFormat: () => {
    return !!(monacoEditor && pyodide);
  }
};

// --- Pyodide Interop ---
window.pyodideInterop = {
  init: async (onOutput) => {
    try {
      pyodide = await loadPyodide();

      // [MODIFIED] Temporarily set empty handlers to silence package loading
      pyodide.setStdout({ batched: () => {} });
      pyodide.setStderr({ batched: () => {} });

      // [MODIFIED] All manual onOutput calls are commented out for a silent init
      // onOutput('Initializing Python environment...\n');
      await pyodide.loadPackage(['micropip', 'typing-extensions']);

      const micropip = pyodide.pyimport('micropip');

      // onOutput('Installing Black formatter and dependencies...\n');
      await micropip.install(['black==23.9.1', 'click==8.1.7']);

      // [MODIFIED] Test the installation silently without printing the version
      await pyodide.runPythonAsync(`import black`);

      // [MODIFIED] Restore the real output handlers for user code execution
      pyodide.setStdout({ batched: (msg) => onOutput(msg + '\n') });
      pyodide.setStderr({ batched: (msg) => onOutput(msg + '\n') });

      // onOutput('Ready to execute Python code.\n');
      return 'Pyodide Initialized Successfully.';

    } catch (error) {
      console.error('Pyodide initialization error:', error);
      // Restore handlers even on error so subsequent messages can be shown
      pyodide.setStdout({ batched: (msg) => onOutput(msg + '\n') });
      pyodide.setStderr({ batched: (msg) => onOutput(msg + '\n') });
      onOutput(`Error: Pyodide failed to initialize.\n${error}\n`);
      return `Pyodide initialization failed: ${error}`;
    }
  },

  runCode: async (code) => {
    if (!pyodide) return "Pyodide not initialized.";

    const sanitizedCode = sanitizeCode(code);

    try {
      await pyodide.runPythonAsync(sanitizedCode);
      return null; // No error
    } catch (error) {
      return String(error);
    }
  },

  // Method to test if Black is available (no changes needed here)
  testBlack: async () => {
    // ... (rest of the function is unchanged)
  },

  // Simple method to check Pyodide status (no changes needed here)
  getStatus: () => {
    // ... (rest of the function is unchanged)
  }
};
