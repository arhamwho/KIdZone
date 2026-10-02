import 'package:flutter/foundation.dart';

import '../models/child_model.dart';

/// In-memory family selection so parent screens share the same child.
class FamilySession extends ChangeNotifier {
  FamilySession._();

  static final FamilySession instance = FamilySession._();

  String? _selectedChildId;

  String? get selectedChildId => _selectedChildId;

  void selectChild(String? childId) {
    if (_selectedChildId == childId) return;
    _selectedChildId = childId;
    notifyListeners();
  }

  ChildModel? resolve(List<ChildModel> children) {
    if (children.isEmpty) return null;
    final String? id = _selectedChildId;
    if (id != null) {
      for (final ChildModel child in children) {
        if (child.uid == id) return child;
      }
    }
    return children.first;
  }

  void hydrate(List<ChildModel> children) {
    if (children.isEmpty) {
      _selectedChildId = null;
      return;
    }
    if (_selectedChildId == null ||
        children.every((ChildModel child) => child.uid != _selectedChildId)) {
      _selectedChildId = children.first.uid;
    }
  }

  void syncWith(List<ChildModel> children) {
    if (children.isEmpty) {
      if (_selectedChildId != null) {
        _selectedChildId = null;
        notifyListeners();
      }
      return;
    }
    final bool missing =
        _selectedChildId == null ||
        children.every((ChildModel child) => child.uid != _selectedChildId);
    if (missing) {
      _selectedChildId = children.first.uid;
      notifyListeners();
    }
  }

  void clear() {
    _selectedChildId = null;
  }
}
