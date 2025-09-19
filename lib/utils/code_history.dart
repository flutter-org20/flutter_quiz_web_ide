class CodeHistory {
  final List<String> _history = [];
  int _currentIndex = -1;

  void addState(String state) {
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    _history.add(state);
    _currentIndex = _history.length - 1;

    if (_history.length > 50) {
      _history.removeAt(0);
      _currentIndex = _history.length - 1;
    }
  }

  String? undo() {
    if (canUndo()) {
      _currentIndex--;
      return _history[_currentIndex];
    }
    return _history.isNotEmpty ? _history.first : null;
  }

  String? redo() {
    if (canRedo()) {
      _currentIndex++;
      return _history[_currentIndex];
    }
    return _history.isNotEmpty ? _history.last : null;
  }

  bool canUndo() => _currentIndex > 0;
  bool canRedo() => _currentIndex >= 0 && _currentIndex < _history.length - 1;

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}