import 'package:flutter/material.dart';

class ToolBar extends StatelessWidget {
  final double fontSize;
  final bool showSpecialChars;
  final VoidCallback onSelectAll;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onPrettify;
  final VoidCallback onToggleSpecialChars;
  final VoidCallback onRun;
  final VoidCallback onClear;
  final Function(String) onSpecialCharInsert;
  final bool canUndo;
  final bool canRedo;

  const ToolBar({
    super.key,
    required this.fontSize,
    required this.showSpecialChars,
    required this.onSelectAll,
    required this.onCopy,
    required this.onPaste,
    required this.onUndo,
    required this.onRedo,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onPrettify,
    required this.onToggleSpecialChars,
    required this.onRun,
    required this.onClear,
    required this.onSpecialCharInsert,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: const Border(bottom: BorderSide(color: Color(0xFF404040))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMainToolbar(),
          if (showSpecialChars) _buildSpecialCharToolbar(),
        ],
      ),
    );
  }

  Widget _buildMainToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Edit Controls
            _buildButtonGroup('Edit', [
              _buildToolbarButton(
                icon: Icons.select_all,
                label: 'Select All',
                onPressed: onSelectAll,
                tooltip: 'Select All (Ctrl+A)',
                color: Colors.blue,
              ),
              _buildToolbarButton(
                icon: Icons.copy,
                label: 'Copy',
                onPressed: onCopy,
                tooltip: 'Copy (Ctrl+C)',
                color: Colors.green,
              ),
              _buildToolbarButton(
                icon: Icons.paste,
                label: 'Paste',
                onPressed: onPaste,
                tooltip: 'Paste (Ctrl+V)',
                color: Colors.orange,
              ),
            ]),

            // History Controls
            _buildButtonGroup('History', [
              _buildToolbarButton(
                icon: Icons.undo,
                label: 'Undo',
                onPressed: canUndo ? onUndo : null,
                tooltip: 'Undo (Ctrl+Z)',
                color: canUndo ? Colors.blue[400] : Colors.grey,
                isDisabled: !canUndo,
              ),
              _buildToolbarButton(
                icon: Icons.redo,
                label: 'Redo',
                onPressed: canRedo ? onRedo : null,
                tooltip: 'Redo (Ctrl+Y)',
                color: canRedo ? Colors.blue[400] : Colors.grey,
                isDisabled: !canRedo,
              ),
            ]),

            // Font Controls
            _buildButtonGroup('Font', [
              _buildToolbarButton(
                icon: Icons.zoom_in,
                label: 'Zoom+',
                onPressed: onZoomIn,
                tooltip: 'Increase Font Size (${fontSize.toInt()}px)',
                color: Colors.purple[400],
              ),
              _buildToolbarButton(
                icon: Icons.zoom_out,
                label: 'Zoom-',
                onPressed: onZoomOut,
                tooltip: 'Decrease Font Size (${fontSize.toInt()}px)',
                color: Colors.purple[400],
              ),
            ]),

            // Code Tools
            _buildButtonGroup('Tools', [
              _buildToolbarButton(
                icon: Icons.auto_fix_high,
                label: 'Prettify',
                onPressed: onPrettify,
                color: Colors.indigo,
                tooltip: 'Auto-format Python Code',
              ),
              _buildToolbarButton(
                icon: showSpecialChars ? Icons.keyboard_hide : Icons.keyboard,
                label: showSpecialChars ? 'Hide Special Ch' : 'Show Special Ch',
                onPressed: onToggleSpecialChars,
                tooltip: 'Toggle Special Characters Panel',
                isActive: showSpecialChars,
                color: Colors.cyan,
              ),
            ]),

            // Execution Controls
            _buildButtonGroup('Execute', [
              _buildToolbarButton(
                icon: Icons.play_arrow,
                label: 'Run',
                onPressed: onRun,
                tooltip: 'Run Python Code (F5)',
                color: Colors.green[600],
                isPrimary: true,
              ),
              _buildToolbarButton(
                icon: Icons.clear_all,
                label: 'Clear',
                onPressed: onClear,
                tooltip: 'Clear Output Console',
                color: Colors.red[400],
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialCharToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(top: BorderSide(color: Color(0xFF404040))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with collapse indicator
          Row(
            children: [
              const Icon(Icons.keyboard, color: Colors.cyan, size: 16),
              const SizedBox(width: 8),
              Text(
                'Python Special Characters & Keywords',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.keyboard_arrow_up, color: Colors.grey[400], size: 16),
            ],
          ),
          const SizedBox(height: 12),
          // Special characters sections
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpecialCharGroup('Operators', Colors.orange[300]!, [
                  SpecialChar('==', 'Equal to'),
                  SpecialChar('!=', 'Not equal'),
                  SpecialChar('<=', 'Less or equal'),
                  SpecialChar('>=', 'Greater or equal'),
                  SpecialChar('//', 'Floor division'),
                  SpecialChar('', 'Power/Exponent'),
                  SpecialChar('+=', 'Add and assign'),
                  SpecialChar('-=', 'Subtract and assign'),
                  SpecialChar('*=', 'Multiply and assign'),
                  SpecialChar('/=', 'Divide and assign'),
                ]),

                _buildSpecialCharGroup('Logic', Colors.green[300]!, [
                  SpecialChar('and ', 'Logical AND'),
                  SpecialChar('or ', 'Logical OR'),
                  SpecialChar('not ', 'Logical NOT'),
                  SpecialChar('in ', 'Membership test'),
                  SpecialChar('is ', 'Identity test'),
                  SpecialChar('is not ', 'Negative identity'),
                  SpecialChar('not in ', 'Negative membership'),
                ]),

                _buildSpecialCharGroup('Brackets', Colors.blue[300]!, [
                  SpecialChar('[]', 'List literal'),
                  SpecialChar('{}', 'Dict/Set literal'),
                  SpecialChar('()', 'Tuple/Function call'),
                  SpecialChar('[:]', 'Slice notation'),
                  SpecialChar('{}', 'F-string placeholder'),
                  SpecialChar('""', 'String literal'),
                  SpecialChar("''", 'String literal'),
                  SpecialChar('"""', 'Multi-line string'),
                ]),

                _buildSpecialCharGroup('Special', Colors.yellow[300]!, [
                  SpecialChar('\\n', 'Newline character'),
                  SpecialChar('\\t', 'Tab character'),
                  SpecialChar('\\r', 'Carriage return'),
                  SpecialChar('\\\\', 'Backslash literal'),
                  SpecialChar('\\"', 'Escaped quote'),
                  SpecialChar("\\'", 'Escaped apostrophe'),
                  SpecialChar('# ', 'Comment'),
                  SpecialChar('_', 'Underscore/Private'),
                  SpecialChar('', 'Dunder prefix'),
                  SpecialChar('...', 'Ellipsis'),
                  SpecialChar('None', 'None value'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGroup(String title, List<Widget> buttons) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group title
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Buttons row
          Row(
            children:
                buttons
                    .map(
                      (button) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: button,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
    Color? color,
    bool isActive = false,
    bool isPrimary = false,
    bool isDisabled = false,
  }) {
    final effectiveColor =
        isDisabled
            ? Colors.grey[600]
            : isActive
            ? Colors.blue
            : color ?? const Color(0xFF404040);

    return Tooltip(
      message: tooltip ?? label,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isActive
                    ? Colors.blue
                    : isPrimary
                    ? Colors.green
                    : Colors.transparent,
            width: isActive || isPrimary ? 1.5 : 0,
          ),
          boxShadow:
              isPrimary
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: effectiveColor?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color:
                        isDisabled
                            ? Colors.grey[600]
                            : effectiveColor ?? Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color:
                          isDisabled
                              ? Colors.grey[600]
                              : effectiveColor ?? Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialCharGroup(
    String title,
    Color titleColor,
    List<SpecialChar> chars,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: titleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Character buttons
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children:
                chars
                    .map((char) => _buildSpecialCharButton(char, titleColor))
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialCharButton(SpecialChar specialChar, Color groupColor) {
    return Tooltip(
      message: '${specialChar.character} - ${specialChar.description}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSpecialCharInsert(specialChar.character),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: groupColor.withOpacity(0.5), width: 1),
            ),
            child: Text(
              specialChar.character,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpecialChar {
  final String character;
  final String description;

  SpecialChar(this.character, this.description);
}
