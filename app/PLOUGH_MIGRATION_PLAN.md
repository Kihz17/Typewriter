# GraphView to Plough Library Migration Plan

## Executive Summary

This document outlines a comprehensive, zero-risk migration strategy from the current GraphView library (with automatic SugiyamaAlgorithm positioning) to the Plough library with manual node positioning and persistent storage. The migration preserves all existing functionality while adding drag-and-drop repositioning capabilities.

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Migration Objectives](#migration-objectives)
3. [Risk Assessment & Mitigation](#risk-assessment--mitigation)
4. [Detailed Migration Plan](#detailed-migration-plan)
5. [Implementation Phases](#implementation-phases)
6. [Data Model Changes](#data-model-changes)
7. [Component Architecture](#component-architecture)
8. [Testing Strategy](#testing-strategy)
9. [Rollback Plan](#rollback-plan)
10. [Post-Migration Cleanup](#post-migration-cleanup)

## Current State Analysis

### Existing Dependencies
```yaml
# Current pubspec.yaml dependency
graphview: ^1.2.0
```

### Current Graph Components
1. **EntriesGraph** (`/app/lib/widgets/components/app/entries_graph.dart`)
   - Purpose: Displays trigger entries in left-to-right flow
   - Algorithm: SugiyamaAlgorithm with ORIENTATION_LEFT_RIGHT
   - Node separation: 40px, Level separation: 40px

2. **ManifestView** (`/app/lib/widgets/components/app/manifest_view.dart`)  
   - Purpose: Displays manifest entries in top-to-bottom flow
   - Algorithm: SugiyamaAlgorithm with ORIENTATION_TOP_BOTTOM
   - Node separation: 40px, Level separation: 40px

### Current Data Flow
```
Entry (data model) → Riverpod providers → Graph building → GraphView rendering
```

### Existing Features to Preserve
- **Interactive pan/zoom** via InteractiveViewer
- **Node selection** with visual feedback
- **Long-press drag-and-drop** for entry connections
- **Context menus** with entry actions
- **External entry nodes** from other pages
- **Error state handling** for missing/invalid entries
- **Real-time updates** via Riverpod reactivity

## Migration Objectives

### Primary Goals
1. **Enable manual node positioning** via left-click drag-and-drop
2. **Persist node positions** across sessions in database
3. **Maintain all existing functionality** without regression
4. **Zero downtime migration** with instant rollback capability
5. **Gradual rollout** with A/B testing support

### Success Criteria
- [ ] All existing graph interactions preserved
- [ ] Nodes repositionable via drag-and-drop
- [ ] Positions persist across app restarts
- [ ] Performance equal or better than current implementation
- [ ] No breaking changes to existing data
- [ ] Feature flag enables safe rollout

## Risk Assessment & Mitigation

### High-Risk Areas

#### 1. Data Model Changes
**Risk**: Breaking existing entry data structure
**Mitigation**: 
- Add optional position fields to Entry model
- Maintain backwards compatibility with existing entries
- Use migration scripts for database schema updates

#### 2. API Incompatibilities
**Risk**: Plough API differs significantly from GraphView
**Mitigation**:
- Create abstraction layer for common functionality
- Parallel implementation approach
- Comprehensive API mapping documentation

#### 3. Performance Degradation
**Risk**: Manual positioning may impact rendering performance
**Mitigation**:
- Benchmark current vs new implementation
- Optimize position calculations
- Implement position caching strategies

#### 4. User Experience Disruption
**Risk**: Different interaction patterns may confuse users
**Mitigation**:
- Maintain existing interaction patterns
- Add progressive disclosure for new features
- Comprehensive user testing

### Medium-Risk Areas

#### 1. State Management Integration
**Risk**: Plough may not integrate cleanly with Riverpod
**Mitigation**: Custom providers for position management

#### 2. Edge Case Handling
**Risk**: Complex scenarios not covered in initial implementation
**Mitigation**: Comprehensive edge case documentation and testing

#### 3. Third-Party Dependency Risk
**Risk**: Plough library maintenance or compatibility issues
**Mitigation**: Fork library if needed, maintain GraphView as fallback

## Detailed Migration Plan

## Implementation Phases

### Phase 1: Foundation & Setup (Week 1)

#### 1.1 Dependencies & Environment Setup

**Add Plough Dependency**
```yaml
# pubspec.yaml additions
dependencies:
  plough: ^0.3.0  # Add alongside existing graphview
  # Keep graphview: ^1.2.0 during migration
```

**Feature Flag System**
```dart
// lib/utils/feature_flags.dart
enum GraphRenderingEngine { graphview, plough }

@riverpod
GraphRenderingEngine graphRenderingEngine(GraphRenderingEngineRef ref) {
  // Default to graphview for safety
  return GraphRenderingEngine.graphview;
  
  // TODO: Later read from settings/config
  // final settings = ref.watch(appSettingsProvider);
  // return settings.graphEngine;
}
```

#### 1.2 Data Model Extensions

**Extend Entry Model for Positions**
```dart
// lib/models/entry.dart additions

// Add to Entry class
class Entry {
  // ... existing code ...
  
  /// Optional node position for manual graph layout
  /// Only present if user has manually positioned this node
  GraphPosition? get graphPosition {
    final pos = data['graphPosition'];
    if (pos is Map<String, dynamic>) {
      return GraphPosition.fromJson(pos);
    }
    return null;
  }
  
  /// Set graph position for this entry
  void setGraphPosition(GraphPosition position) {
    data['graphPosition'] = position.toJson();
  }
  
  /// Clear manual positioning, allowing automatic layout
  void clearGraphPosition() {
    data.remove('graphPosition');
  }
  
  /// Whether this entry has a manually set position
  bool get hasManualPosition => data.containsKey('graphPosition');
}
```

**Create GraphPosition Model**
```dart
// lib/models/graph_position.dart
import 'package:flutter/material.dart';

class GraphPosition {
  const GraphPosition({
    required this.x,
    required this.y,
    this.timestamp,
  });
  
  final double x;
  final double y;
  final DateTime? timestamp; // For conflict resolution
  
  factory GraphPosition.fromOffset(Offset offset, {DateTime? timestamp}) {
    return GraphPosition(
      x: offset.dx,
      y: offset.dy,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
  
  factory GraphPosition.fromJson(Map<String, dynamic> json) {
    return GraphPosition(
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };
  
  Offset toOffset() => Offset(x, y);
  
  GraphPosition copyWith({double? x, double? y, DateTime? timestamp}) {
    return GraphPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      other is GraphPosition && 
      other.x == x && 
      other.y == y;
  
  @override
  int get hashCode => Object.hash(x, y);
}
```

#### 1.3 Position Management Providers

**Create Position Management System**
```dart
// lib/providers/graph_positions.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/graph_position.dart';
import '../models/entry.dart';

part 'graph_positions.g.dart';

@riverpod
class EntryPositionManager extends _$EntryPositionManager {
  @override
  Map<String, GraphPosition> build() {
    return {};
  }
  
  /// Get position for entry, with fallback to automatic positioning
  GraphPosition? getPosition(String entryId) {
    // First check manual positions
    if (state.containsKey(entryId)) {
      return state[entryId];
    }
    
    // Check entry data for persisted position
    final entry = ref.read(globalEntryProvider(entryId));
    return entry?.graphPosition;
  }
  
  /// Set position for entry and persist
  Future<void> setPosition(String entryId, GraphPosition position) async {
    // Update in-memory state
    state = {...state, entryId: position};
    
    // Persist to entry data
    final entry = ref.read(globalEntryProvider(entryId));
    if (entry != null) {
      entry.setGraphPosition(position);
      
      // Trigger page save through existing mechanisms
      final pageId = ref.read(entryPageIdProvider(entryId));
      if (pageId != null) {
        final page = ref.read(pageProvider(pageId));
        await page?.saveEntryPosition(ref, entryId, position);
      }
    }
  }
  
  /// Remove manual position, allowing automatic layout
  Future<void> clearPosition(String entryId) async {
    state = Map.fromEntries(
      state.entries.where((entry) => entry.key != entryId),
    );
    
    final entry = ref.read(globalEntryProvider(entryId));
    if (entry != null) {
      entry.clearGraphPosition();
      
      // Trigger page save
      final pageId = ref.read(entryPageIdProvider(entryId));
      if (pageId != null) {
        final page = ref.read(pageProvider(pageId));
        await page?.saveEntryPosition(ref, entryId, null);
      }
    }
  }
  
  /// Get positions for all entries on a page
  Map<String, GraphPosition> getPagePositions(String pageId) {
    final page = ref.read(pageProvider(pageId));
    if (page == null) return {};
    
    final positions = <String, GraphPosition>{};
    for (final entry in page.entries) {
      final pos = getPosition(entry.id);
      if (pos != null) {
        positions[entry.id] = pos;
      }
    }
    return positions;
  }
}

/// Provider for automatic fallback positioning when no manual position exists
@riverpod
GraphPosition? entryAutoPosition(EntryAutoPositionRef ref, String entryId) {
  // This will generate automatic positions for entries without manual ones
  // Using a simple grid layout as fallback
  final entries = ref.watch(graphableEntriesProvider);
  final index = entries.indexWhere((e) => e.id == entryId);
  
  if (index == -1) return null;
  
  // Simple grid layout fallback
  const nodeSpacing = 200.0;
  final cols = 4;
  final row = index ~/ cols;
  final col = index % cols;
  
  return GraphPosition(
    x: col * nodeSpacing + 100,
    y: row * nodeSpacing + 100,
  );
}
```

### Phase 2: Plough Implementation (Week 2-3)

#### 2.1 Create Parallel Components

**Abstract Graph Interface**
```dart
// lib/widgets/components/app/graph_interface.dart
abstract class GraphInterface extends Widget {
  const GraphInterface({super.key});
  
  /// Whether this implementation supports manual positioning
  bool get supportsManualPositioning;
  
  /// Get current graph engine type
  GraphRenderingEngine get engine;
}
```

**Plough-based EntriesGraph**
```dart
// lib/widgets/components/app/plough_entries_graph.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plough/plough.dart';
import '../../../providers/graph_positions.dart';
import '../../../utils/feature_flags.dart';
import 'graph_interface.dart';

class PloughEntriesGraph extends HookConsumerWidget implements GraphInterface {
  const PloughEntriesGraph({super.key});
  
  @override
  bool get supportsManualPositioning => true;
  
  @override
  GraphRenderingEngine get engine => GraphRenderingEngine.plough;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(graphableEntriesProvider);
    final positionManager = ref.watch(entryPositionManagerProvider.notifier);
    
    // Build Plough graph
    final graph = _buildPloughGraph(ref, entries);
    
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width,
        vertical: MediaQuery.of(context).size.height,
      ),
      minScale: 0.0001,
      maxScale: 2.6,
      child: GraphView(
        graph: graph,
        layoutStrategy: _buildManualLayoutStrategy(ref, entries),
        behavior: _buildGraphBehavior(ref, positionManager),
        nodeRenderer: _buildNodeRenderer(ref),
        linkRenderer: _buildLinkRenderer(ref),
      ),
    );
  }
  
  Graph _buildPloughGraph(WidgetRef ref, List<Entry> entries) {
    final graph = Graph();
    
    // Add nodes
    for (final entry in entries) {
      final node = GraphNode(
        properties: {
          'entryId': entry.id,
          'entry': entry,
        },
      );
      graph.addNode(node);
    }
    
    // Add edges based on triggers
    for (final entry in entries) {
      final triggeredEntryIds = ref.watch(entryTriggersProvider(entry.id));
      if (triggeredEntryIds == null) continue;
      
      final sourceNode = graph.nodes.firstWhere(
        (n) => n.properties['entryId'] == entry.id,
      );
      
      for (final triggeredEntryId in triggeredEntryIds) {
        if (triggeredEntryId == entry.id) continue;
        
        try {
          final targetNode = graph.nodes.firstWhere(
            (n) => n.properties['entryId'] == triggeredEntryId,
          );
          
          final blueprintColor = ref.watch(
            entryBlueprintProvider(entry.blueprintId)
          )?.color ?? Colors.grey;
          
          graph.addLink(GraphLink(
            source: sourceNode,
            target: targetNode,
            properties: {
              'color': blueprintColor,
              'sourceEntryId': entry.id,
              'targetEntryId': triggeredEntryId,
            },
          ));
        } catch (e) {
          // Target node not in current graph (external reference)
          // Will be handled by external node rendering
        }
      }
    }
    
    return graph;
  }
  
  GraphLayoutStrategy _buildManualLayoutStrategy(
    WidgetRef ref, 
    List<Entry> entries,
  ) {
    final positions = <GraphNode, Offset>{};
    
    // Get manual positions for entries that have them
    for (final entry in entries) {
      final position = ref.watch(entryPositionManagerProvider.notifier)
          .getPosition(entry.id);
      
      if (position != null) {
        final node = // find node for this entry
        positions[node] = position.toOffset();
      }
    }
    
    // Use manual layout with fallback
    if (positions.isNotEmpty) {
      return GraphManualLayoutStrategy(
        nodePositions: positions,
        // Fallback to force-directed for unpositioned nodes
        fallbackStrategy: GraphForceDirectedLayoutStrategy(
          iterations: 100,
          repulsion: 1000,
          attraction: 0.1,
        ),
      );
    } else {
      // No manual positions yet, use force-directed as starting point
      return GraphForceDirectedLayoutStrategy(
        iterations: 100,
        repulsion: 1000,
        attraction: 0.1,
      );
    }
  }
  
  GraphViewBehavior _buildGraphBehavior(
    WidgetRef ref,
    EntryPositionManager positionManager,
  ) {
    return GraphViewBehavior(
      onNodePanUpdate: (node, details) async {
        final entryId = node.properties['entryId'] as String?;
        if (entryId == null) return;
        
        // Update position during drag
        final newPosition = GraphPosition.fromOffset(details.localPosition);
        await positionManager.setPosition(entryId, newPosition);
      },
      onNodeTap: (node) {
        final entryId = node.properties['entryId'] as String?;
        if (entryId == null) return;
        
        // Select entry (preserve existing behavior)
        ref.read(inspectingEntryIdProvider.notifier).selectEntry(entryId);
      },
      onNodeLongPress: (node) {
        final entryId = node.properties['entryId'] as String?;
        if (entryId == null) return;
        
        // Show context menu (preserve existing behavior)
        _showNodeContextMenu(ref, entryId);
      },
    );
  }
  
  Widget Function(GraphNode) _buildNodeRenderer(WidgetRef ref) {
    return (node) {
      final entryId = node.properties['entryId'] as String?;
      if (entryId == null) return const SizedBox();
      
      // Use existing EntryNode component
      return EntryNode(
        entryId: entryId,
        key: ValueKey('plough-$entryId'),
      );
    };
  }
  
  Widget Function(GraphLink) _buildLinkRenderer(WidgetRef ref) {
    return (link) {
      final color = link.properties['color'] as Color? ?? Colors.green;
      
      // Custom edge renderer to match current styling
      return CustomPaint(
        painter: GraphEdgePainter(
          color: color,
          strokeWidth: 1.0,
        ),
      );
    };
  }
  
  void _showNodeContextMenu(WidgetRef ref, String entryId) {
    // Implement context menu (preserve existing functionality)
    // This would integrate with existing ContextMenuRegion logic
  }
}

// Custom painter for graph edges
class GraphEdgePainter extends CustomPainter {
  const GraphEdgePainter({
    required this.color,
    required this.strokeWidth,
  });
  
  final Color color;
  final double strokeWidth;
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    // Draw line from start to end
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

**Plough-based ManifestView**
```dart
// lib/widgets/components/app/plough_manifest_view.dart
// Similar implementation to PloughEntriesGraph but for manifest entries
// with vertical orientation preference in fallback positioning
```

#### 2.2 Graph Selector Component

**Create Graph Engine Selector**
```dart
// lib/widgets/components/app/adaptive_graph_view.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../utils/feature_flags.dart';
import 'entries_graph.dart';
import 'plough_entries_graph.dart';
import 'manifest_view.dart';
import 'plough_manifest_view.dart';

enum GraphType { entries, manifest }

class AdaptiveGraphView extends HookConsumerWidget {
  const AdaptiveGraphView({
    required this.type,
    super.key,
  });
  
  final GraphType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(graphRenderingEngineProvider);
    
    switch (engine) {
      case GraphRenderingEngine.graphview:
        return _buildGraphViewImplementation();
      case GraphRenderingEngine.plough:
        return _buildPloughImplementation();
    }
  }
  
  Widget _buildGraphViewImplementation() {
    switch (type) {
      case GraphType.entries:
        return const EntriesGraph();
      case GraphType.manifest:
        return const ManifestView();
    }
  }
  
  Widget _buildPloughImplementation() {
    switch (type) {
      case GraphType.entries:
        return const PloughEntriesGraph();
      case GraphType.manifest:
        return const PloughManifestView();
    }
  }
}
```

### Phase 3: Integration & Feature Parity (Week 4)

#### 3.1 Update Page Editor Integration

**Modify Page Editor to Use Adaptive Graph**
```dart
// lib/pages/page_editor.dart modifications
import '../widgets/components/app/adaptive_graph_view.dart';

class _PageContent extends HookConsumerWidget {
  const _PageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageType = ref.watch(currentPageTypeProvider);
    if (pageType == null) {
      return const SizedBox();
    }

    switch (pageType) {
      case PageType.sequence:
        return const AdaptiveGraphView(type: GraphType.entries);
      case PageType.static:
        return const StaticEntriesList();
      case PageType.cinematic:
        return const CinematicView();
      case PageType.manifest:
        return const AdaptiveGraphView(type: GraphType.manifest);
    }
  }
}
```

#### 3.2 Position Persistence Backend Integration

**Extend Page Model for Position Saving**
```dart
// lib/models/page.dart additions
class Page {
  // ... existing code ...
  
  /// Save entry position to backend
  Future<void> saveEntryPosition(
    PassingRef ref,
    String entryId,
    GraphPosition? position,
  ) async {
    final entry = entries.firstWhere((e) => e.id == entryId);
    
    if (position != null) {
      entry.setGraphPosition(position);
    } else {
      entry.clearGraphPosition();
    }
    
    // Use existing save mechanism
    await save(ref);
  }
  
  /// Get all manual positions for entries on this page
  Map<String, GraphPosition> getManualPositions() {
    final positions = <String, GraphPosition>{};
    
    for (final entry in entries) {
      final pos = entry.graphPosition;
      if (pos != null) {
        positions[entry.id] = pos;
      }
    }
    
    return positions;
  }
}
```

#### 3.3 Advanced Features Implementation

**Add Graph Controls UI**
```dart
// lib/widgets/components/app/graph_controls.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../utils/feature_flags.dart';
import '../../../providers/graph_positions.dart';

class GraphControls extends HookConsumerWidget {
  const GraphControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(graphRenderingEngineProvider);
    final supportsManual = engine == GraphRenderingEngine.plough;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Engine selector (dev/admin only)
            if (kDebugMode) ...[
              DropdownButton<GraphRenderingEngine>(
                value: engine,
                items: GraphRenderingEngine.values.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  );
                }).toList(),
                onChanged: (value) {
                  // TODO: Update engine preference
                },
              ),
              const SizedBox(width: 16),
            ],
            
            // Auto-arrange button
            if (supportsManual) ...[
              IconButton(
                icon: const Icon(Icons.auto_fix_high),
                tooltip: 'Auto-arrange nodes',
                onPressed: () => _autoArrangeNodes(ref),
              ),
              
              // Reset positions button
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'Reset to automatic positioning',
                onPressed: () => _resetPositions(ref),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _autoArrangeNodes(WidgetRef ref) async {
    final entries = ref.read(graphableEntriesProvider);
    final positionManager = ref.read(entryPositionManagerProvider.notifier);
    
    // Apply force-directed layout and save positions
    // This would run a layout algorithm and set the resulting positions
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      // Calculate position using force-directed algorithm
      final position = _calculateForceDirectedPosition(entries, i);
      await positionManager.setPosition(entry.id, position);
    }
  }
  
  Future<void> _resetPositions(WidgetRef ref) async {
    final entries = ref.read(graphableEntriesProvider);
    final positionManager = ref.read(entryPositionManagerProvider.notifier);
    
    // Clear all manual positions
    for (final entry in entries) {
      await positionManager.clearPosition(entry.id);
    }
  }
  
  GraphPosition _calculateForceDirectedPosition(List<Entry> entries, int index) {
    // Implement force-directed layout calculation
    // This is a simplified version - real implementation would be more complex
    const spacing = 200.0;
    final cols = 4;
    final row = index ~/ cols;
    final col = index % cols;
    
    return GraphPosition(
      x: col * spacing + 100,
      y: row * spacing + 100,
    );
  }
}
```

### Phase 4: Testing & Validation (Week 5)

#### 4.1 Comprehensive Testing Strategy

**Unit Tests**
```dart
// test/graph_position_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/graph_position.dart';

void main() {
  group('GraphPosition', () {
    test('should create from offset', () {
      const offset = Offset(100, 200);
      final position = GraphPosition.fromOffset(offset);
      
      expect(position.x, 100);
      expect(position.y, 200);
      expect(position.toOffset(), offset);
    });
    
    test('should serialize to/from JSON', () {
      final original = GraphPosition(
        x: 150.5,
        y: 250.7,
        timestamp: DateTime.now(),
      );
      
      final json = original.toJson();
      final restored = GraphPosition.fromJson(json);
      
      expect(restored.x, original.x);
      expect(restored.y, original.y);
      expect(restored.timestamp, original.timestamp);
    });
    
    test('should handle equality correctly', () {
      const pos1 = GraphPosition(x: 100, y: 200);
      const pos2 = GraphPosition(x: 100, y: 200);
      const pos3 = GraphPosition(x: 101, y: 200);
      
      expect(pos1, equals(pos2));
      expect(pos1, isNot(equals(pos3)));
    });
  });
}

// test/position_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../lib/providers/graph_positions.dart';

void main() {
  group('EntryPositionManager', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('should set and get positions', () async {
      final manager = container.read(entryPositionManagerProvider.notifier);
      const position = GraphPosition(x: 100, y: 200);
      
      await manager.setPosition('entry-1', position);
      final retrieved = manager.getPosition('entry-1');
      
      expect(retrieved, equals(position));
    });
    
    test('should clear positions', () async {
      final manager = container.read(entryPositionManagerProvider.notifier);
      const position = GraphPosition(x: 100, y: 200);
      
      await manager.setPosition('entry-1', position);
      await manager.clearPosition('entry-1');
      
      final retrieved = manager.getPosition('entry-1');
      expect(retrieved, isNull);
    });
  });
}
```

**Integration Tests**
```dart
// integration_test/graph_migration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:typewriter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Graph Migration Tests', () {
    testWidgets('should render both GraphView and Plough implementations', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to graph view
      // ... navigation code ...
      
      // Test GraphView implementation
      // Switch to GraphView mode
      await tester.pumpAndSettle();
      expect(find.byType(EntriesGraph), findsOneWidget);
      
      // Test Plough implementation
      // Switch to Plough mode
      await tester.pumpAndSettle();
      expect(find.byType(PloughEntriesGraph), findsOneWidget);
    });
    
    testWidgets('should preserve node drag functionality', (tester) async {
      // Test drag and drop positioning
      // Verify positions are saved and restored
    });
    
    testWidgets('should handle feature flag switching', (tester) async {
      // Test switching between implementations
      // Verify no data loss during switching
    });
  });
}
```

#### 4.2 Performance Benchmarking

**Create Performance Test Suite**
```dart
// test/performance/graph_benchmark.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Graph Performance', () {
    test('GraphView vs Plough rendering performance', () async {
      final stopwatch = Stopwatch();
      
      // Test GraphView performance
      stopwatch.start();
      // ... render GraphView with test data ...
      stopwatch.stop();
      final graphViewTime = stopwatch.elapsedMilliseconds;
      
      // Test Plough performance
      stopwatch.reset();
      stopwatch.start();
      // ... render Plough with same test data ...
      stopwatch.stop();
      final ploughTime = stopwatch.elapsedMilliseconds;
      
      print('GraphView render time: ${graphViewTime}ms');
      print('Plough render time: ${ploughTime}ms');
      
      // Ensure performance is acceptable (within 50% of GraphView)
      expect(ploughTime, lessThan(graphViewTime * 1.5));
    });
    
    test('Position update performance', () async {
      // Test how quickly positions can be updated
      final stopwatch = Stopwatch();
      
      stopwatch.start();
      // ... update 100 node positions ...
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
```

### Phase 5: Gradual Rollout (Week 6)

#### 5.1 Feature Flag Implementation

**Create Settings-Based Feature Flag**
```dart
// lib/models/app_settings.dart additions
class AppSettings {
  // ... existing fields ...
  
  final GraphRenderingEngine graphEngine;
  final bool enableManualPositioning;
  final bool showGraphControls;
  
  AppSettings copyWith({
    // ... existing parameters ...
    GraphRenderingEngine? graphEngine,
    bool? enableManualPositioning,
    bool? showGraphControls,
  }) {
    return AppSettings(
      // ... existing assignments ...
      graphEngine: graphEngine ?? this.graphEngine,
      enableManualPositioning: enableManualPositioning ?? this.enableManualPositioning,
      showGraphControls: showGraphControls ?? this.showGraphControls,
    );
  }
}

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  AppSettings build() {
    return const AppSettings(
      // ... existing defaults ...
      graphEngine: GraphRenderingEngine.graphview, // Safe default
      enableManualPositioning: false,
      showGraphControls: false,
    );
  }
  
  Future<void> updateGraphEngine(GraphRenderingEngine engine) async {
    state = state.copyWith(graphEngine: engine);
    await _saveSettings();
  }
  
  Future<void> _saveSettings() async {
    // Save to persistent storage
  }
}
```

**Update Feature Flag Provider**
```dart
// lib/utils/feature_flags.dart updates
@riverpod
GraphRenderingEngine graphRenderingEngine(GraphRenderingEngineRef ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.graphEngine;
}

@riverpod
bool enableManualPositioning(EnableManualPositioningRef ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.enableManualPositioning && 
         settings.graphEngine == GraphRenderingEngine.plough;
}
```

#### 5.2 Rollout Strategy

**Phase 5.1: Internal Testing (Days 1-2)**
- Enable Plough for development/staging environments only
- Internal team testing and feedback
- Performance monitoring and optimization

**Phase 5.2: Beta Testing (Days 3-5)**
- Enable feature flag for beta users
- Collect user feedback
- Monitor for crashes or performance issues

**Phase 5.3: Gradual Production Rollout (Days 6-7)**
- 10% of users → Plough enabled
- 50% of users → Plough enabled  
- 100% of users → Plough enabled (if no issues)

**Rollout Monitoring**
```dart
// lib/utils/analytics.dart additions
class GraphAnalytics {
  static void trackGraphEngineUsage(GraphRenderingEngine engine) {
    // Track which engine is being used
  }
  
  static void trackNodePositioning(String entryId, GraphPosition position) {
    // Track when users manually position nodes
  }
  
  static void trackPerformanceMetric(String metric, int value) {
    // Track performance metrics for comparison
  }
  
  static void trackError(String engine, String error) {
    // Track errors by engine type
  }
}
```

## Rollback Plan

### Immediate Rollback (0-5 minutes)
If critical issues are detected:
1. **Feature Flag Disable**: Set `graphRenderingEngine` to `GraphRenderingEngine.graphview`
2. **All users immediately revert** to stable GraphView implementation
3. **No data loss** - positions remain saved for future Plough use

### Partial Rollback (5-30 minutes)
If issues affect specific user groups:
1. **Targeted rollback** for affected user segments
2. **Preserve position data** for non-affected users
3. **Gradual re-enablement** as issues are resolved

### Complete Rollback (30+ minutes)
If fundamental issues require code changes:
1. **Remove Plough dependency** from pubspec.yaml
2. **Remove Plough components** (but keep position data structures)
3. **Revert to GraphView-only implementation**
4. **Position data preserved** for future migration attempts

### Data Recovery
```dart
// lib/utils/migration_recovery.dart
class MigrationRecovery {
  /// Export all manual positions before rollback
  static Future<Map<String, dynamic>> exportPositions() async {
    // Export all position data
  }
  
  /// Import positions after recovery
  static Future<void> importPositions(Map<String, dynamic> data) async {
    // Restore position data
  }
  
  /// Validate data integrity
  static Future<bool> validatePositionData() async {
    // Ensure no data corruption occurred
  }
}
```

## Post-Migration Cleanup

### Phase 6: Optimization & Cleanup (Week 7+)

#### 6.1 Performance Optimization
- **Position caching strategies**
- **Lazy loading of off-screen nodes**
- **Edge rendering optimization**
- **Memory usage optimization**

#### 6.2 Remove GraphView Dependency
After 2 weeks of stable Plough usage:
1. **Remove graphview dependency** from pubspec.yaml
2. **Remove old GraphView components**
3. **Clean up unused imports and code**
4. **Update documentation**

#### 6.3 Advanced Features
Once stable:
- **Grid snap positioning**
- **Multi-select node operations**
- **Node grouping and clustering**
- **Advanced layout algorithms**
- **Collaborative positioning (if multi-user)**

## Success Metrics

### Technical Metrics
- [ ] **Zero data loss** during migration
- [ ] **Performance parity** (within 20% of GraphView)
- [ ] **100% feature parity** with existing functionality
- [ ] **<1% error rate** in production

### User Experience Metrics
- [ ] **User adoption** of manual positioning features
- [ ] **User satisfaction** scores maintained or improved
- [ ] **Support ticket volume** remains stable
- [ ] **Task completion time** for graph operations

### Business Metrics
- [ ] **No impact** on user engagement
- [ ] **Positive feedback** on new positioning features
- [ ] **Reduced development time** for future graph features

## Conclusion

This migration plan provides a comprehensive, risk-free approach to upgrading from GraphView to Plough library while adding manual node positioning capabilities. The parallel implementation strategy ensures zero downtime and instant rollback capability, while the gradual rollout minimizes risk to users.

Key advantages of this approach:
- ✅ **Zero breaking changes** during migration
- ✅ **Instant rollback capability** at any point
- ✅ **Preserved data integrity** throughout process
- ✅ **Comprehensive testing strategy** ensures quality
- ✅ **User-centered approach** with gradual feature introduction

The migration maintains all existing functionality while providing users with powerful new manual positioning capabilities and persistent storage of their preferred layouts.