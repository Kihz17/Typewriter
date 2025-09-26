import 'dart:async';
import 'dart:ui';

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/empty_screen.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";

const double kVirtualCanvasSize = 200000;

class DraggableGraph extends ConsumerStatefulWidget {
  final List<String> entryIds;
  final Map<String, Set<String>> edges;
  final String emptyTitle;
  final String emptyButtonText;
  final VoidCallback onEmptyButtonPressed;

  const DraggableGraph({
    super.key,
    required this.entryIds,
    required this.edges,
    required this.emptyTitle,
    required this.emptyButtonText,
    required this.onEmptyButtonPressed,
  });

  @override
  ConsumerState<DraggableGraph> createState() => _DraggableGraphState();
}

class _DraggableGraphState extends ConsumerState<DraggableGraph> with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  Rect _visibleRect = Rect.zero;
  List<String> _visibleNodes = [];
  Timer? _throttleTimer;
  late final AnimationController _animController;

  // In-memory storage for node sizes and measurement keys
  final Map<String, Size> _nodeSizes = {};
  final Map<String, GlobalKey> _nodeKeys = {};

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
      _centerCameraOnNodes();
    });
  }

  @override
  void didUpdateWidget(covariant DraggableGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the entry IDs changed (indicating a page change)
    if (widget.entryIds != oldWidget.entryIds) {
      // Schedule camera centering after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerCameraOnNodes();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onViewportChanged);
    _controller.dispose();
    _throttleTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _initializeNodePositions() {
    final page = ref.read(currentPageProvider);
    if (page == null) return;

    for (int i = 0; i < widget.entryIds.length; i++) {
      final id = widget.entryIds[i];
      final pos = page.nodePositions[id];
      if (pos == null) {
        final initialOffset = Offset(100.0 + 200.0 * i, 100.0);
        page.updateNodePosition(ref.passing, id, initialOffset);
      }
    }
  }

  Offset _getNodePosition(String nodeId) {
    final page = ref.watch(currentPageProvider);
    if (page == null) {
      debugPrint("Page was null when accessing position for node. This is a bug.");
      return Offset.zero;
    }

    return page.nodePositions[nodeId] ?? Offset.zero;
  }

  void _measureNodeIfNeeded(String nodeId) {
    if (_nodeSizes[nodeId] != null) return; // Already measured

    final key = _nodeKeys[nodeId];
    if (key?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final renderBox = key!.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && mounted) {
          setState(() {
            _nodeSizes[nodeId] = renderBox.size;
          });
        }
      });
    }
  }

  void _onViewportChanged() {
    // Throttle viewport changes to avoid flooding rebuilds
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 50), () {
      final matrix = _controller.value;
      final screenSize = MediaQuery.of(context).size;

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
      final newVisibleNodes = widget.entryIds.where((id) {
        final pos = _getNodePosition(id);
        final nodeRect = Rect.fromLTWH(pos.dx, pos.dy, 120, 60);
        return newVisibleRect.overlaps(nodeRect);
      }).toList();

      setState(() {
        _visibleRect = newVisibleRect;
        _visibleNodes = newVisibleNodes;
      });

      // Clean up sizes and keys for nodes that are no longer visible
      _cleanupOffscreenNodes();
    });
  }

  void _cleanupOffscreenNodes() {
    final visibleSet = _visibleNodes.toSet();
    final currentEntrySet = widget.entryIds.toSet();

    // Remove sizes for nodes that are no longer visible or no longer in entryIds
    _nodeSizes.removeWhere((nodeId, _) =>
      !visibleSet.contains(nodeId) && !currentEntrySet.contains(nodeId));

    // Remove keys for nodes that are no longer in entryIds
    _nodeKeys.removeWhere((nodeId, _) => !currentEntrySet.contains(nodeId));
  }

  void _centerCameraOnNodes() {
    final page = ref.read(currentPageProvider);
    if (page == null || widget.entryIds.isEmpty) return;

    // Get all existing node positions
    final nodePositions = <Offset>[];
    for (final id in widget.entryIds) {
      final position = page.nodePositions[id];
      if (position != null) {
        nodePositions.add(position);
      }
    }

    // If no nodes have saved positions, don't center (they'll use default positions)
    if (nodePositions.isEmpty) return;

    // Calculate bounding box of all nodes (accounting for node size 120x60)
    const nodeSize = Size(120, 60);
    double minX = nodePositions.first.dx;
    double maxX = nodePositions.first.dx + nodeSize.width;
    double minY = nodePositions.first.dy;
    double maxY = nodePositions.first.dy + nodeSize.height;

    for (final pos in nodePositions) {
      minX = minX < pos.dx ? minX : pos.dx;
      maxX = maxX > (pos.dx + nodeSize.width) ? maxX : (pos.dx + nodeSize.width);
      minY = minY < pos.dy ? minY : pos.dy;
      maxY = maxY > (pos.dy + nodeSize.height) ? maxY : (pos.dy + nodeSize.height);
    }

    // Calculate center point of all nodes
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    // Get screen size to calculate viewport center
    final screenSize = MediaQuery.of(context).size;
    final viewportCenterX = screenSize.width / 2;
    final viewportCenterY = screenSize.height / 2;

    // Calculate translation needed to center the nodes in the viewport
    final translateX = viewportCenterX - centerX;
    final translateY = viewportCenterY - centerY;

    // Create transformation matrix to center the camera
    final matrix = Matrix4.identity()
      ..translate(translateX, translateY);

    // Apply the transformation
    _controller.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entryIds.isEmpty) {
      return EmptyScreen(
        title: widget.emptyTitle,
        buttonText: widget.emptyButtonText,
        onButtonPressed: widget.onEmptyButtonPressed,
      );
    }

    return InteractiveViewer(
      transformationController: _controller,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1),
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
                final positions = widget.entryIds
                    .map((id) => MapEntry(id, _getNodePosition(id)))
                    .toMap();

                return CustomPaint(
                  painter: EdgePainter(
                    positions: positions,
                    edges: widget.edges,
                    visibleNodes: _visibleNodes,
                    visibleRect: _visibleRect,
                    dashOffset: _animController.value,
                    nodeSizes: _nodeSizes,
                    onNodeSizeNeeded: _measureNodeIfNeeded,
                  ),
                );
              },
            ),
            // Render only visible nodes
            ..._visibleNodes.map((id) {
              return Consumer( // Wrap in consumer to isolate the provider, meaning when we drag a node, the entire graph does not need to update
                builder: (context, ref, _) {
                  final position = _getNodePosition(id);

                  // Ensure node has a GlobalKey for measurement
                  _nodeKeys[id] ??= GlobalKey();

                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final newPos = Offset(
                          (position.dx + details.delta.dx).clamp(0.0, double.infinity),
                          (position.dy + details.delta.dy).clamp(0.0, double.infinity),
                        );
                        // Immediately update local position for smooth dragging
                        final page = ref.read(currentPageProvider);
                        if (page != null) {
                          page.syncUpdateNodePosition(ref.passing, id, newPos);
                        }
                      },
                      onPanEnd: (details) {
                        // Since the client who is panning gets predicted updates, we can update all the other clients on pan end
                        final position = _getNodePosition(id);

                        final page = ref.read(currentPageProvider);
                        if (page != null) {
                          page.updateNodePosition(ref.passing, id, position);
                        }
                      },
                      child: KeyedSubtree(
                        key: _nodeKeys[id],
                        child: EntryNode(entryId: id, key: ValueKey(id)),
                      ),
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
  final Rect visibleRect;
  final double dashOffset; // 0..1
  final Color color;
  final Map<String, Size> nodeSizes;
  final void Function(String) onNodeSizeNeeded;

  EdgePainter({
    required this.positions,
    required this.edges,
    required this.visibleNodes,
    required this.visibleRect,
    required this.dashOffset,
    required this.nodeSizes,
    required this.onNodeSizeNeeded,
    this.color = Colors.green,
  });

  bool _lineIntersectsRect(Offset from, Offset to) {
    // Check if either point is inside the rect (fast path)
    if (visibleRect.contains(from) || visibleRect.contains(to)) {
      return true;
    }

    // Use Liang-Barsky line clipping algorithm
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;

    final p = [-dx, dx, -dy, dy];
    final q = [
      from.dx - visibleRect.left,
      visibleRect.right - from.dx,
      from.dy - visibleRect.top,
      visibleRect.bottom - from.dy
    ];

    double u1 = 0.0;
    double u2 = 1.0;

    for (int i = 0; i < 4; i++) {
      if (p[i] == 0) {
        // Line is parallel to the boundary
        if (q[i] < 0) return false;
      } else {
        final t = q[i] / p[i];
        if (p[i] < 0) {
          if (t > u2) return false;
          if (t > u1) u1 = t;
        } else {
          if (t < u1) return false;
          if (t < u2) u2 = t;
        }
      }
    }

    return u1 <= u2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final arrowSize = 6.0; // length of arrow lines
    final arrowWidth = 7.0; // angle at tip
    final arrowSpacing = 20.0; // distance between arrows along edge

    final points = <Offset>[];

    edges.forEach((fromId, toIds) {
      // Get actual sizes or defaults, trigger measurement if needed
      final fromSize = nodeSizes[fromId] ?? const Size(120, 60);
      if (nodeSizes[fromId] == null) {
        onNodeSizeNeeded(fromId);
      }

      // Calculate center offset for from node
      final fromOffset = Offset(fromSize.width / 2, fromSize.height / 2);
      final from = (positions[fromId] ?? Offset.zero) + fromOffset;

      for (final toId in toIds) {
        // Get actual sizes or defaults, trigger measurement if needed
        final toSize = nodeSizes[toId] ?? const Size(120, 60);
        if (nodeSizes[toId] == null) {
          onNodeSizeNeeded(toId);
        }

        // Calculate center offset for to node
        final toOffset = Offset(toSize.width / 2, toSize.height / 2);
        final to = (positions[toId] ?? Offset.zero) + toOffset;

        // Performance optimization: if edge is not visible, don't render
        if (!_lineIntersectsRect(from, to)) continue;

        final direction = to - from;
        final length = direction.distance;
        if (length == 0) continue;

        final unit = direction / length;
        final perp = Offset(-unit.dy, unit.dx) * (arrowWidth / 2);

        final totalArrows = (length / arrowSpacing).ceil();

        for (int i = 0; i < totalArrows; i++) {
          // Animated offset along the edge
          final t = ((i * arrowSpacing) + dashOffset * arrowSpacing) % length;
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
        visibleRect != oldDelegate.visibleRect ||
        nodeSizes != oldDelegate.nodeSizes ||
        (dashOffset - oldDelegate.dashOffset).abs() > 0.01;
  }
}

// Extension to convert Iterable<MapEntry> to Map
extension ToMap<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> toMap() {
    return Map.fromEntries(this);
  }
}