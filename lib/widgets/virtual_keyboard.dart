import 'package:flutter/material.dart';

class VirtualKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onDone;

  const VirtualKeyboard({super.key, required this.controller, this.onDone});

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard>
    with TickerProviderStateMixin {
  bool _isCaps = false;
  bool _isSymbols = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<List<String>> _letterRows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  final List<List<String>> _symbolRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['!', '@', '#', '\$', '%', '^', '&', '*', '(', ')'],
    ['-', '_', '=', '+', '[', ']', '{', '}', '\\', '|'],
    [';', ':', '\'', '"', ',', '.', '<', '>', '/', '?'],
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the animation when keyboard appears
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row indicators
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSymbols ? _buildSymbolLayout() : _buildLetterLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterLayout() {
    return Column(
      key: const ValueKey('letters'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Letter rows
        ..._letterRows.map((row) => _buildKeyRow(row)),
        // Bottom row with special keys
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildSymbolLayout() {
    return Column(
      key: const ValueKey('symbols'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Symbol rows
        ..._symbolRows.map((row) => _buildKeyRow(row)),
        // Bottom row with special keys
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) => _buildKey(key)).toList(),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Symbol toggle
          _buildSpecialKey(
            _isSymbols ? 'ABC' : '?123',
            flex: 2,
            onPressed: () {
              setState(() {
                _isSymbols = !_isSymbols;
              });
            },
          ),
          const SizedBox(width: 4),
          // Space bar
          _buildSpecialKey('Space', flex: 4, onPressed: () => _insertText(' ')),
          const SizedBox(width: 4),
          // Caps lock (only show in letter mode)
          if (!_isSymbols) ...[
            _buildSpecialKey(
              _isCaps ? 'caps' : 'CAPS',
              flex: 2,
              onPressed: () {
                setState(() {
                  _isCaps = !_isCaps;
                });
              },
              isActive: _isCaps,
            ),
            const SizedBox(width: 4),
          ],
          // Backspace
          _buildSpecialKey(
            '⌫',
            flex: 2,
            onPressed: _handleBackspace,
            icon: Icons.backspace_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    final displayKey = _isSymbols ? key : (_isCaps ? key.toUpperCase() : key);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _insertText(displayKey),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[600]!
                          : Colors.grey[300]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  displayKey,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(
    String label, {
    required int flex,
    required VoidCallback onPressed,
    IconData? icon,
    bool isActive = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onPressed,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color:
                    isActive
                        ? Theme.of(context).primaryColor.withOpacity(0.8)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]
                            : Colors.white),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      isActive
                          ? Theme.of(context).primaryColor
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]!
                              : Colors.grey[300]!),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child:
                    icon != null
                        ? Icon(
                          icon,
                          size: 20,
                          color:
                              isActive
                                  ? Colors.white
                                  : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87),
                        )
                        : Text(
                          label,
                          style: TextStyle(
                            fontSize: label == 'Space' ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color:
                                isActive
                                    ? Colors.white
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87),
                          ),
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _insertText(String text) {
    final currentText = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isValid) {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: selection.start + text.length),
      );
    } else {
      widget.controller.text = currentText + text;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
    }
  }

  void _handleBackspace() {
    final currentText = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isValid && selection.start > 0) {
      if (selection.isCollapsed) {
        // Delete single character before cursor
        final newText = currentText.replaceRange(
          selection.start - 1,
          selection.start,
          '',
        );
        widget.controller.text = newText;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: selection.start - 1),
        );
      } else {
        // Delete selected text
        final newText = currentText.replaceRange(
          selection.start,
          selection.end,
          '',
        );
        widget.controller.text = newText;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: selection.start),
        );
      }
    }
  }
}
