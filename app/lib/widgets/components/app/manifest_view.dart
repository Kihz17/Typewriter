import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/widgets/components/app/draggable_graph.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";

part "manifest_view.g.dart";

@riverpod
List<Entry> manifestEntries(Ref ref) {
  final page = ref.watch(currentPageProvider);
  if (page == null) return [];

  return page.entries.where((entry) {
    final tags = ref.watch(entryBlueprintTagsProvider(entry.blueprintId));
    if (tags.isEmpty) {
      // Entries without a blueprint are always shown. So that the user can delete them.
      return true;
    }
    return tags.contains("manifest");
  }).toList();
}

@riverpod
List<String> manifestEntryIds(Ref ref) {
  final currentPageEntries = ref.watch(manifestEntriesProvider);
  final currentPageEntryIds = currentPageEntries.map((entry) => entry.id).toSet();

  // Get all referenced manifest entries from current page entries
  final referencedEntryIds = <String>{};
  for (final entry in currentPageEntries) {
    final referenceEntryIds = ref.watch(entryReferencesProvider(entry.id));
    if (referenceEntryIds != null) {
      for (final referenceEntryId in referenceEntryIds) {
        final referenceTags = ref.watch(entryTagsProvider(referenceEntryId));
        if (referenceTags.contains("manifest") && referenceEntryId != entry.id) {
          referencedEntryIds.add(referenceEntryId);
        }
      }
    }
  }

  // Combine current page entries with referenced entries
  final allEntryIds = {...currentPageEntryIds, ...referencedEntryIds};
  return allEntryIds.toList();
}

@riverpod
Set<String>? entryReferences(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return null;

  final modifiers =
      ref.watch(modifierPathsProvider(entry.blueprintId, "entry"));
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
Offset manifestNodePosition(Ref ref, String nodeId) {
  final page = ref.watch(currentPageProvider);
  if (page == null) {
    debugPrint("Page was null when accessing position for node. This is a bug.");
    return Offset.zero;
  }

  return page.nodePositions[nodeId] ?? Offset.zero;
}

@riverpod
Map<String, Set<String>> manifestEdges(Ref ref) {
  final entries = ref.watch(manifestEntriesProvider);
  final Map<String, Set<String>> edges = {};

  for (final entry in entries) {
    final referenceEntryIds = ref.watch(entryReferencesProvider(entry.id));
    if (referenceEntryIds == null) {
      edges[entry.id] = {};
      continue;
    }

    // Include all manifest references regardless of page
    final manifestReferences = referenceEntryIds.where((referenceEntryId) {
      final referenceTags = ref.watch(entryTagsProvider(referenceEntryId));
      return referenceTags.contains("manifest") &&
             referenceEntryId != entry.id;
    }).toSet();

    edges[entry.id] = manifestReferences;
  }

  return edges;
}

class ManifestView extends HookConsumerWidget {
  const ManifestView({super.key}) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryIds = ref.watch(manifestEntryIdsProvider);
    final edges = ref.watch(manifestEdgesProvider);
    final currentPageEntries = ref.watch(manifestEntriesProvider);
    final currentPageEntryIds = currentPageEntries.map((entry) => entry.id).toSet();

    return DraggableGraph(
      entryIds: entryIds,
      edges: edges,
      currentPageEntryIds: currentPageEntryIds,
      emptyTitle: "There are no manifest entries on this page.",
      emptyButtonText: "Add Entry",
      onEmptyButtonPressed: () => ref.read(searchProvider.notifier).asBuilder()
        ..fetchNewEntry()
        ..nonGenericAddEntry()
        ..tag("manifest")
        ..open(),
    );
  }
}
