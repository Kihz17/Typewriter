import "dart:convert";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

part "node_position_service.g.dart";

@riverpod
NodePositionService nodePositionService(Ref ref) {
  return NodePositionService();
}

@riverpod
class NodePositions extends _$NodePositions {
  static const String _storageKey = "node_positions";

  @override
  Map<String, Offset> build() {
    _loadPositions();
    return {};
  }

  Future<void> _loadPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionsJson = prefs.getString(_storageKey);
      
      if (positionsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(positionsJson);
        final Map<String, Offset> positions = {};
        
        for (final entry in decoded.entries) {
          final Map<String, dynamic> offsetData = entry.value;
          positions[entry.key] = Offset(
            (offsetData['dx'] as num).toDouble(),
            (offsetData['dy'] as num).toDouble(),
          );
        }
        
        state = positions;
      }
    } catch (e) {
      // If loading fails, use empty map
      state = {};
    }
  }

  Future<void> setPosition(String entryId, Offset position) async {
    state = {...state, entryId: position};
    await _savePositions();
  }

  Future<void> removePosition(String entryId) async {
    if (!state.containsKey(entryId)) return;
    
    final newState = Map<String, Offset>.from(state);
    newState.remove(entryId);
    state = newState;
    await _savePositions();
  }

  Future<void> clearAllPositions() async {
    state = {};
    await _savePositions();
  }

  Future<void> _savePositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> serializable = {};
      
      for (final entry in state.entries) {
        serializable[entry.key] = {
          'dx': entry.value.dx,
          'dy': entry.value.dy,
        };
      }
      
      await prefs.setString(_storageKey, jsonEncode(serializable));
    } catch (e) {
      // Handle save errors silently
    }
  }
}

@riverpod
class GraphLayoutMode extends _$GraphLayoutMode {
  static const String _layoutModeKey = "graph_layout_mode";

  @override
  GraphLayoutModeType build() {
    _loadLayoutMode();
    return GraphLayoutModeType.automatic;
  }

  Future<void> _loadLayoutMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_layoutModeKey);
      if (modeString != null) {
        final mode = GraphLayoutModeType.values
            .firstWhere((e) => e.toString() == modeString, 
                      orElse: () => GraphLayoutModeType.automatic);
        state = mode;
      }
    } catch (e) {
      state = GraphLayoutModeType.automatic;
    }
  }

  Future<void> setLayoutMode(GraphLayoutModeType mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_layoutModeKey, mode.toString());
    } catch (e) {
      // Handle save errors silently
    }
  }
}

enum GraphLayoutModeType {
  automatic,
  manual,
}

class NodePositionService {
  Offset? getPosition(String entryId, Map<String, Offset> positions) {
    return positions[entryId];
  }

  bool hasPosition(String entryId, Map<String, Offset> positions) {
    return positions.containsKey(entryId);
  }
}