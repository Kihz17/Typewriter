import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:graphview/GraphView.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/widgets/components/app/empty_screen.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import 'dart:async';
import 'dart:ui';

part "entries_graph.g.dart";

const double kVirtualCanvasSize = 200000;

@riverpod
List<Entry> graphableEntries(Ref ref) {
  final page = ref.watch(currentPageProvider);
  if (page == null) return [];

  return page.entries.where((entry) {
    final tags = ref.watch(entryBlueprintTagsProvider(entry.blueprintId));
    if (tags.isEmpty) {
      // Entries without a blueprint are always shown. So that the user can delete them.
      return true;
    }
    return tags.contains("trigger");
  }).toList();
}

@riverpod
List<String> graphableEntryIds(Ref ref) {
  final entries = ref.watch(graphableEntriesProvider);
  return entries.map((entry) => entry.id).toList();
}

@riverpod
bool isTriggerEntry(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return false;

  final tags = ref.watch(entryBlueprintTagsProvider(entry.blueprintId));
  return tags.contains("trigger");
}

@riverpod
bool isTriggerableEntry(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return false;

  final tags = ref.watch(entryBlueprintTagsProvider(entry.blueprintId));
  return tags.contains("triggerable");
}

@riverpod
Set<String>? entryTriggers(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return null;

  // Check if this entry is a trigger
  if (!ref.read(isTriggerEntryProvider(entryId))) return null;

  final modifiers = ref
      .watch(modifierPathsProvider(entry.blueprintId, "entry", "triggerable"));
  return modifiers
      .expand(entry.getAll)
      .expand((value) {
        if (value is String) {
          return [value];
        }
        // The keys of a map can also be entries
        if (value is Map) {
          return value.keys.map((key) => key.toString());
        }

        return <String>[];
      })
      .where((id) => id.isNotEmpty)
      .toSet();
}

@riverpod
Graph graph(Ref ref) {
  final entries = ref.watch(graphableEntriesProvider);
  final graph = Graph();

  for (final entry in entries) {
    final node = Node.Id(entry.id);
    graph.addNode(node);
  }

  for (final entry in entries) {
    final triggeredEntryIds = ref.watch(entryTriggersProvider(entry.id));
    if (triggeredEntryIds == null) continue;

    final color = ref.watch(entryBlueprintProvider(entry.blueprintId))?.color ??
        Colors.grey;

    for (final triggeredEntryId in triggeredEntryIds) {
      if (triggeredEntryId == entry.id) continue;
      graph.addEdge(
        Node.Id(entry.id),
        Node.Id(triggeredEntryId),
        paint: Paint()..color = color,
      );
    }
  }

  return graph;
}

final nodePositionProvider =
StateNotifierProvider.autoDispose.family<NodePositionNotifier, Offset, String>(
        (ref, nodeId) => NodePositionNotifier());

class NodePositionNotifier extends StateNotifier<Offset> {
  NodePositionNotifier() : super(Offset.zero);

  void setPosition(Offset position) => state = position;
}

class EntriesGraph extends ConsumerStatefulWidget {
  const EntriesGraph({super.key});

  @override
  ConsumerState<EntriesGraph> createState() => _EntriesGraphState();
}

class _EntriesGraphState extends ConsumerState<EntriesGraph> with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  Rect _visibleRect = Rect.zero;
  List<String> _visibleNodes = [];
  Timer? _throttleTimer;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();

    // Setup anim controller for animated edges
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // continuously loops

    // Listen for viewport changes (pan/zoom)
    _controller.addListener(_onViewportChanged);

    // Initialize viewport culling immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onViewportChanged();
      _initializeNodePositions();
    });
  }

  @override
  void dispose() {
    debugPrint("Disposing GraphEntries");

    _controller.removeListener(_onViewportChanged);
    _controller.dispose();
    _throttleTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _initializeNodePositions() {
    final entryIds = ref.read(graphableEntryIdsProvider);
    for (int i = 0; i < entryIds.length; i++) {
      final id = entryIds[i];
      final pos = ref.read(nodePositionProvider(id));
      if (pos == Offset.zero) {
        final initialOffset = Offset(100.0 + 200.0 * i, 100.0);
        ref.read(nodePositionProvider(id).notifier).setPosition(initialOffset);
      }
    }
  }

  void _onViewportChanged() {
    // Throttle viewport changes to avoid flooding rebuilds
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 50), () {
      final matrix = _controller.value;
      final screenSize = MediaQuery
          .of(context)
          .size;

      // Screen rect in screen space
      final screenRect = Rect.fromLTWH(
          0, 0, screenSize.width, screenSize.height);

      // Transform into world/graph space
      final inverseMatrix = Matrix4.inverted(matrix);
      final worldTopLeft = MatrixUtils.transformPoint(
          inverseMatrix, screenRect.topLeft);
      final worldBottomRight = MatrixUtils.transformPoint(
          inverseMatrix, screenRect.bottomRight);

      // This is the new rect we will use for viewport culling
      final newVisibleRect = Rect.fromPoints(worldTopLeft, worldBottomRight);

      // Compute the nodes we can see relative to the viewport
      final entryIds = ref.read(graphableEntryIdsProvider);
      final newVisibleNodes = entryIds.where((id) {
        final pos = ref.read(nodePositionProvider(id));
        final nodeRect = Rect.fromLTWH(pos.dx, pos.dy, 120,
            60); // TODO: Don't make constant height (120, 60), get actual node dimensions
        return newVisibleRect.overlaps(nodeRect);
      }).toList();

      setState(() {
        _visibleRect = newVisibleRect;
        _visibleNodes = newVisibleNodes;
      });

      debugPrint("Visible rect updated: $_visibleRect");
    });
  }

  @override
  Widget build(BuildContext context) {
    final entryIds = ref.watch(graphableEntryIdsProvider);

    if (entryIds.isEmpty) {
      return EmptyScreen(
        title: "There are no graphable entries on this page.",
        buttonText: "Add Entry",
        onButtonPressed: () => ref.read(searchProvider.notifier).asBuilder()
          ..fetchNewEntry()
          ..nonGenericAddEntry()
          ..tag("trigger")
          ..open(),
      );
    }

    final Map<String, Set<String>> edges = {};
    for (final entry in ref.watch(graphableEntriesProvider)) {
      final triggeredIds = ref.watch(entryTriggersProvider(entry.id)) ?? {};
      edges[entry.id] = triggeredIds;
    }

    return InteractiveViewer(
      transformationController: _controller,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.1,
      maxScale: 2.5,
      child: SizedBox(
        width: kVirtualCanvasSize,
        height: kVirtualCanvasSize,
        child: Stack(
          children: [
            // Paint edges only if their endpoints are visible
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: EdgePainter(
                  positions: entryIds
                      .map((id) => MapEntry(id, ref.watch(nodePositionProvider(id))))
                      .toMap(),
                  edges: edges,
                  visibleNodes: _visibleNodes,
                  dashOffset: _animController.value,
                  ),
                );
              },
            ),
            // Render only visible nodes
            ..._visibleNodes.map((id) {
              return Consumer( // Wrap in consumer to isolate the provider, meaning when we drag a node, the entire graph does not need to update
                builder: (context, ref, _) {
                  final position = ref.watch(nodePositionProvider(id));

                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final newPos = Offset(
                          (position.dx + details.delta.dx).clamp(0.0, double.infinity),
                          (position.dy + details.delta.dy).clamp(0.0, double.infinity),
                        );
                        ref.read(nodePositionProvider(id).notifier).setPosition(newPos);
                      },
                      child: EntryNode(entryId: id, key: ValueKey(id)),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class EdgePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final Map<String, Set<String>> edges;
  final List<String> visibleNodes;
  final double dashOffset; // 0..1
  final Color color;

  EdgePainter({
    required this.positions,
    required this.edges,
    required this.visibleNodes,
    required this.dashOffset,
    this.color = Colors.green,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final edgeOffset = Offset(100, 25);
    final arrowSize = 6.0; // length of arrow lines
    final arrowWidth = 7.0; // angle at tip
    final arrowSpacing = 20.0; // distance between arrows along edge
    final arrowSpeed = 2.0;

    final points = <Offset>[];

    edges.forEach((fromId, toIds) {
      final from = (positions[fromId] ?? Offset.zero)  + edgeOffset;
      if (from == null) return;

      final visibleFrom = visibleNodes.contains(fromId);

      for (final toId in toIds) {
        if (!visibleNodes.contains(toId) && !visibleFrom) continue;

        final to = (positions[toId] ?? Offset.zero) + edgeOffset;
        if (to == null) continue;

        final direction = to - from;
        final length = direction.distance;
        if (length == 0) continue;

        final unit = direction / length;
        final perp = Offset(-unit.dy, unit.dx) * (arrowWidth / 2);

        final totalArrows = (length / arrowSpacing).ceil();

        for (int i = 0; i < totalArrows; i++) {
          // Animated offset along the edge
          final t = ((i * arrowSpacing) + dashOffset * arrowSpacing * arrowSpeed) % length;
          final center = from + unit * t;

          final tip = center + unit * arrowSize;

          // Add two line segments for the arrowhead
          points.add(tip);
          points.add(center + perp);

          points.add(tip);
          points.add(center - perp);
        }
      }
    });

    // Batch draw calls
    canvas.drawPoints(PointMode.lines, points, paint);
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return positions != oldDelegate.positions ||
        edges != oldDelegate.edges ||
        visibleNodes != oldDelegate.visibleNodes ||
        (dashOffset - oldDelegate.dashOffset).abs() > 0.01;
  }
}

// ------------------- Extension to convert Iterable<MapEntry> to Map -------------------
extension ToMap<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> toMap() {
    return Map.fromEntries(this);
  }
}
