import 'dart:async';
import 'dart:math';
import 'dart:ui';

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/entry.dart";
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
  final Set<String>? currentPageEntryIds; // Optional: entries that are on current page

  const DraggableGraph({
    super.key,
    required this.entryIds,
    required this.edges,
    required this.emptyTitle,
    required this.emptyButtonText,
    required this.onEmptyButtonPressed,
    this.currentPageEntryIds,
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
  String? _lastPageId; // Track current page ID to detect page changes

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

    // Initialize page tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final page = ref.read(currentPageProvider);
      _lastPageId = page?.id;
    });

    // Initialize viewport culling immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onViewportChanged();
      _initializeNodePositions();
      _relocateOutlierNodes();
      _centerCameraOnNodes();
    });
  }

  @override
  void didUpdateWidget(covariant DraggableGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only center camera on actual page navigation, not content changes
    final currentPage = ref.read(currentPageProvider);
    final newPageId = currentPage?.id;

    if (_lastPageId != newPageId) {
      _lastPageId = newPageId;
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

    final currentPageEntryIds = widget.currentPageEntryIds ?? {};

    for (int i = 0; i < widget.entryIds.length; i++) {
      final id = widget.entryIds[i];
      final pos = page.nodePositions[id];
      if (pos == null) {
        final isCurrentPageEntry = currentPageEntryIds.contains(id);

        if (isCurrentPageEntry) {
          // Use simple sequential positioning for same-page entries
          final initialOffset = Offset(100.0 + 200.0 * i, 100.0);
          page.updateNodePosition(ref.passing, id, initialOffset);
        } else {
          // Use smart positioning for external entries to avoid overlaps
          final initialOffset = _generateInitialPosition(id);
          page.updateNodePosition(ref.passing, id, initialOffset);
        }
      }
    }
  }

  Offset _getNodePosition(String nodeId) {
    final page = ref.watch(currentPageProvider);
    if (page == null) {
      debugPrint("Page was null when accessing position for node. This is a bug.");
      return Offset.zero;
    }

    // Check if position exists, if not generate and store a new one
    final existingPosition = page.nodePositions[nodeId];
    if (existingPosition != null) {
      return existingPosition;
    }

    // Generate initial position for external entries
    final newPosition = _generateInitialPosition(nodeId);

    // Store the position immediately so it persists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentPage = ref.read(currentPageProvider);
      if (currentPage != null) {
        currentPage.updateNodePosition(ref.passing, nodeId, newPosition);
      }
    });

    return newPosition;
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
        // Get actual size or default, trigger measurement if needed
        final nodeSize = _nodeSizes[id] ?? const Size(120, 60);
        if (_nodeSizes[id] == null) {
          _measureNodeIfNeeded(id);
        }
        final nodeRect = Rect.fromLTWH(pos.dx, pos.dy, nodeSize.width, nodeSize.height);
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

  Offset _generateInitialPosition(String nodeId) {
    final page = ref.read(currentPageProvider);
    if (page == null) return Offset.zero;

    // Get all existing positions to avoid overlaps
    final existingPositions = page.nodePositions.values.toList();

    // Base position calculation - start after existing same-page entries
    const double baseX = 100.0;
    const double baseY = 100.0;
    const double spacingX = 200.0;
    const double spacingY = 120.0;

    // Find a position that doesn't overlap with existing nodes
    int attempts = 0;
    const int maxAttempts = 100;

    while (attempts < maxAttempts) {
      final candidateX = baseX + (attempts % 10) * spacingX;
      final candidateY = baseY + (attempts ~/ 10) * spacingY;
      final candidatePos = Offset(candidateX, candidateY);

      // Check if this position is too close to any existing position
      bool hasOverlap = false;
      for (final existingPos in existingPositions) {
        final distance = (candidatePos - existingPos).distance;
        if (distance < 150.0) { // Minimum distance between nodes
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return candidatePos;
      }

      attempts++;
    }

    // Fallback: if we can't find a good position, use a basic offset
    return Offset(baseX + existingPositions.length * spacingX, baseY);
  }

  Widget _buildNodeWidget(WidgetRef ref, String entryId) {
    // If currentPageEntryIds is not provided, use EntryNode for all (backward compatibility)
    if (widget.currentPageEntryIds == null) {
      return EntryNode(entryId: entryId, key: ValueKey(entryId));
    }

    // Check if entry is on current page
    final isOnCurrentPage = widget.currentPageEntryIds!.contains(entryId);

    if (isOnCurrentPage) {
      return EntryNode(entryId: entryId, key: ValueKey(entryId));
    } else {
      // Entry is on a different page, use ExternalEntryNode
      final entry = ref.watch(globalEntryProvider(entryId));
      if (entry == null) {
        return EntryNode(entryId: entryId, key: ValueKey(entryId)); // Fallback
      }

      final pageId = ref.watch(entryPageIdProvider(entryId));
      if (pageId == null) {
        return EntryNode(entryId: entryId, key: ValueKey(entryId)); // Fallback
      }

      return ExternalEntryNode(
        pageId: pageId,
        entry: entry,
        key: ValueKey(entryId),
      );
    }
  }

  void _relocateOutlierNodes() {
    final page = ref.read(currentPageProvider);
    if (page == null) return;

    final positions = Map<String, Offset>.from(page.nodePositions);
    if (positions.length < 2) return; // Need at least 2 nodes

    final outliers = <String, Offset>{};

    // Find outliers (nodes >20k from nearest neighbor)
    for (final entry in positions.entries) {
      final nodeId = entry.key;
      final nodePos = entry.value;

      double minDistance = double.infinity;
      for (final otherEntry in positions.entries) {
        if (otherEntry.key == nodeId) continue;
        final distance = (nodePos - otherEntry.value).distance;
        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      if (minDistance > 20000) {
        outliers[nodeId] = nodePos;
      }
    }

    // Relocate outliers closer to cluster
    if (outliers.isNotEmpty) {
      _relocateToCluster(outliers, positions);
    }
  }

  void _relocateToCluster(Map<String, Offset> outliers, Map<String, Offset> allPositions) {
    // Calculate cluster center (excluding outliers)
    final clusterPositions = allPositions.entries
        .where((entry) => !outliers.containsKey(entry.key))
        .map((entry) => entry.value)
        .toList();

    if (clusterPositions.isEmpty) return;

    // Find cluster centroid
    double avgX = clusterPositions.map((pos) => pos.dx).reduce((a, b) => a + b) / clusterPositions.length;
    double avgY = clusterPositions.map((pos) => pos.dy).reduce((a, b) => a + b) / clusterPositions.length;
    final clusterCenter = Offset(avgX, avgY);

    // Relocate each outlier
    for (final outlierEntry in outliers.entries) {
      final nodeId = outlierEntry.key;
      final newPosition = _findClusterEdgePosition(clusterCenter, clusterPositions, nodeId);

      // Update position
      final page = ref.read(currentPageProvider);
      page?.updateNodePosition(ref.passing, nodeId, newPosition);
    }
  }

  Offset _findClusterEdgePosition(Offset clusterCenter, List<Offset> clusterPositions, String nodeId) {
    // Find cluster boundary
    double maxDistanceFromCenter = 0;
    for (final pos in clusterPositions) {
      final distance = (pos - clusterCenter).distance;
      if (distance > maxDistanceFromCenter) {
        maxDistanceFromCenter = distance;
      }
    }

    // Place outlier just outside cluster boundary
    const double bufferDistance = 300.0; // Space from cluster edge
    final placementRadius = maxDistanceFromCenter + bufferDistance;

    // Try different angles to find non-overlapping position
    for (int angle = 0; angle < 360; angle += 30) {
      final radians = angle * (pi / 180);
      final candidatePos = Offset(
        clusterCenter.dx + placementRadius * cos(radians),
        clusterCenter.dy + placementRadius * sin(radians),
      );

      // Check for overlaps with existing nodes
      bool hasOverlap = false;
      for (final pos in clusterPositions) {
        if ((candidatePos - pos).distance < 200) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return candidatePos;
      }
    }

    // Fallback: place at cluster center + offset
    return Offset(clusterCenter.dx + 200, clusterCenter.dy);
  }

  void _centerCameraOnNodes() {
    final page = ref.read(currentPageProvider);
    if (page == null || widget.entryIds.isEmpty) return;

    // Get all existing node positions with their IDs
    final nodeData = <({String id, Offset position})>[];
    for (final id in widget.entryIds) {
      final position = page.nodePositions[id];
      if (position != null) {
        nodeData.add((id: id, position: position));
      }
    }

    // If no nodes have saved positions, don't center (they'll use default positions)
    if (nodeData.isEmpty) return;

    // Initialize bounding box with first node
    final firstNode = nodeData.first;
    final firstNodeSize = _nodeSizes[firstNode.id] ?? const Size(120, 60);
    if (_nodeSizes[firstNode.id] == null) {
      _measureNodeIfNeeded(firstNode.id);
    }

    double minX = firstNode.position.dx;
    double maxX = firstNode.position.dx + firstNodeSize.width;
    double minY = firstNode.position.dy;
    double maxY = firstNode.position.dy + firstNodeSize.height;

    // Calculate bounding box of all nodes using their actual sizes
    for (final node in nodeData) {
      final nodeSize = _nodeSizes[node.id] ?? const Size(120, 60);
      if (_nodeSizes[node.id] == null) {
        _measureNodeIfNeeded(node.id);
      }

      minX = minX < node.position.dx ? minX : node.position.dx;
      maxX = maxX > (node.position.dx + nodeSize.width) ? maxX : (node.position.dx + nodeSize.width);
      minY = minY < node.position.dy ? minY : node.position.dy;
      maxY = maxY > (node.position.dy + nodeSize.height) ? maxY : (node.position.dy + nodeSize.height);
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
                        child: _buildNodeWidget(ref, id),
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