# Graph Visualization System Documentation

## Overview

The Typewriter project includes a sophisticated graph visualization system that displays entries as nodes in an interactive graph view. The system is primarily used in the Flutter app to visualize relationships between different types of entries, particularly trigger-based entries and manifest entries.

## Core Graph Components

### 1. EntriesGraph (`/app/lib/widgets/components/app/entries_graph.dart`)

The main graph visualization component for **trigger entries** (quest/story flow).

#### Key Features:
- Displays entries tagged with "trigger" as nodes
- Shows connections between trigger entries and triggerable entries
- Uses left-to-right hierarchical layout (Sugiyama algorithm)
- Interactive pan and zoom capabilities
- Drag-and-drop support for connecting nodes

#### Main Components:
- **graphableEntries**: Filters entries to show only those with "trigger" tag
- **entryTriggers**: Identifies which entries are triggered by a given entry
- **graph provider**: Builds the graph structure with nodes and edges

### 2. ManifestView (`/app/lib/widgets/components/app/manifest_view.dart`)

Similar graph visualization for **manifest entries** (static data/configuration).

#### Key Features:
- Displays entries tagged with "manifest" as nodes
- Shows reference connections between manifest entries
- Uses top-to-bottom hierarchical layout
- Same interactive capabilities as EntriesGraph

#### Main Components:
- **manifestEntries**: Filters entries with "manifest" tag
- **entryReferences**: Identifies entry references within manifest entries
- **manifestGraph provider**: Builds the graph structure

## Graph Library: GraphView

The system uses the `graphview: ^1.2.0` Flutter package for graph rendering.

### Key GraphView Components:

```dart
GraphView(
  graph: graph,                    // Graph data structure
  algorithm: SugiyamaAlgorithm(),  // Layout algorithm
  paint: Paint(),                  // Edge styling
  builder: (node) => Widget,       // Node widget builder
)
```

### Sugiyama Algorithm Configuration:
- **nodeSeparation**: 40 pixels between nodes
- **levelSeparation**: 40 pixels between hierarchical levels
- **orientation**: 
  - `ORIENTATION_LEFT_RIGHT` for trigger graphs
  - `ORIENTATION_TOP_BOTTOM` for manifest graphs

## Node Components

### EntryNode (`/app/lib/widgets/components/app/entry_node.dart`)

The primary node widget representing an entry in the graph.

#### Features:
- **Visual Representation**:
  - Colored background based on entry blueprint
  - Icon from entry blueprint
  - Entry name display
  - Deprecation indication (strikethrough)
  
- **Interactions**:
  - Click to select/inspect entry
  - Long-press drag to move/connect
  - Context menu with actions:
    - Link with other entries
    - Duplicate entry
    - Move to different page
    - Replace with another entry
    - Delete entry

- **Drag & Drop System**:
  - `LongPressDraggable`: Initiates drag after long press
  - `DragTarget`: Accepts dropped entries
  - `EntryDrag`: Data passed during drag operation
  - Path selector for choosing connection paths

### Node Types:

1. **Regular EntryNode**: Standard node for entries on current page
2. **ExternalEntryNode**: Node for entries from other pages
3. **NonExistentEntry**: Error state for missing entries
4. **NoBlueprintEntry**: Entry without associated blueprint

## Data Flow and State Management

### Riverpod Providers:

The system uses Riverpod for reactive state management:

```dart
// Graph data providers
graphableEntriesProvider     // Filtered trigger entries
graphProvider                 // Complete graph structure
entryTriggersProvider        // Entry trigger relationships

// Manifest providers
manifestEntriesProvider      // Filtered manifest entries
manifestGraphProvider        // Manifest graph structure
entryReferencesProvider      // Entry reference relationships

// Entry state providers
entryBlueprintProvider       // Entry blueprint data
entryNameProvider            // Entry display name
entryTagsProvider            // Entry tags
isEntryDeprecatedProvider    // Deprecation status
```

### Graph Building Process:

1. **Filter entries** based on tags (trigger/manifest)
2. **Create nodes** for each filtered entry
3. **Identify relationships** between entries:
   - For triggers: Look for "triggerable" field modifiers
   - For manifest: Look for "entry" field modifiers
4. **Create edges** between related nodes
5. **Apply layout algorithm** (Sugiyama)
6. **Render interactive graph**

## Road Network System

A separate but related graph system for navigation paths.

### Location: `/extensions/RoadNetworkExtension/`

### Components:

#### RoadNetwork Data Structure:
```kotlin
data class RoadNetwork(
    val nodes: List<RoadNode>,           // Network nodes
    val edges: List<RoadEdge>,           // Connections
    val modifications: List<RoadModification>, // Dynamic changes
    val negativeNodes: List<RoadNode>    // Exclusion zones
)
```

#### RoadNode:
- `id`: Unique identifier
- `position`: World position
- `radius`: Node influence radius

#### RoadEdge:
- `start`: Starting node ID
- `end`: Ending node ID
- `weight`: Connection weight/cost
- `length`: Physical distance

### Use Cases:
- NPC navigation and pathfinding
- Player guidance systems
- World navigation visualization

## File Structure

### Flutter App Files:
```
/app/lib/widgets/components/app/
├── entries_graph.dart       # Trigger entry graph
├── entry_node.dart          # Node component
├── manifest_view.dart       # Manifest entry graph
└── *.g.dart                # Generated Riverpod code
```

### Dependencies:
- `graphview: ^1.2.0` - Graph visualization library
- `hooks_riverpod` - State management
- `flutter_hooks` - React-like hooks for Flutter
- `dotted_border` - Visual effects for dragging

## Page Integration

The graph views are integrated into the page editor based on page type:

```dart
// In page_editor.dart
switch (pageType) {
  case PageType.sequence:
    return const EntriesGraph();    // Trigger graph
  case PageType.manifest:
    return const ManifestView();    // Manifest graph
  // ... other page types
}
```

## Interactive Features

### Pan and Zoom:
- `InteractiveViewer` wrapper provides pan/zoom
- `minScale: 0.0001` allows extensive zoom out
- `maxScale: 2.6` limits zoom in
- Boundary margins allow panning beyond content

### Node Interactions:
1. **Selection**: Click node to inspect in sidebar
2. **Dragging**: Long-press to drag and connect nodes
3. **Context Menu**: Right-click for node actions
4. **Visual Feedback**: 
   - Selected nodes show border
   - Dragging shows dotted placeholder
   - Drop targets show opacity change

### Connection Logic:
1. **Path Selection**: When multiple connection paths exist, user selects from menu
2. **Validation**: System checks if connection is valid based on tags/modifiers
3. **Visual Feedback**: Invalid drop targets show forbidden cursor

## Entry Relationships

### Trigger Relationships:
- Entries with "trigger" tag can trigger "triggerable" entries
- Connections based on field modifiers with "entry" and "triggerable" tags
- One-to-many relationships supported

### Manifest References:
- Manifest entries can reference other manifest entries
- References extracted from entry fields with "entry" modifier
- Supports both direct references and map keys as references

## Customization Points

### Node Appearance:
- Color from entry blueprint
- Icon from entry blueprint
- Custom styling for deprecated entries
- Different styles for external vs local entries

### Graph Layout:
- Orientation (horizontal/vertical)
- Node separation distances
- Edge styling (color, width, style)
- Algorithm parameters

## Performance Considerations

- Graph rebuilds on entry changes via Riverpod reactivity
- Efficient filtering using provider caching
- Lazy loading of external entry data
- Optimized drag-and-drop with visual placeholders

## Summary

The graph visualization system provides a powerful, interactive way to visualize and manipulate entry relationships in the Typewriter project. It combines Flutter's UI capabilities with the graphview library's layout algorithms to create an intuitive interface for managing complex quest structures and data relationships. The system is highly reactive, extensible, and provides rich interaction patterns for users to work with their content effectively.