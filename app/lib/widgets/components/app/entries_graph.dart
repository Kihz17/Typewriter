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

part "entries_graph.g.dart";

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
  final currentPageEntries = ref.watch(graphableEntriesProvider);
  final currentPageEntryIds = currentPageEntries.map((entry) => entry.id).toSet();

  // Get all triggered entries from current page entries
  final triggeredEntryIds = <String>{};
  for (final entry in currentPageEntries) {
    final triggerIds = ref.watch(entryTriggersProvider(entry.id));
    if (triggerIds != null) {
      triggeredEntryIds.addAll(triggerIds);
    }
  }

  // Combine current page entries with triggered entries
  final allEntryIds = {...currentPageEntryIds, ...triggeredEntryIds};
  return allEntryIds.toList();
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
Offset nodePosition(Ref ref, String nodeId) {
  final page = ref.watch(currentPageProvider);
  if (page == null) {
    debugPrint("Page was null when accessing position for node. This is a bug.");
    return Offset.zero;
  }

  return page.nodePositions[nodeId] ?? Offset.zero;
}

@riverpod
Map<String, Set<String>> triggerEdges(Ref ref) {
  final Map<String, Set<String>> edges = {};
  for (final entry in ref.watch(graphableEntriesProvider)) {
    final triggeredIds = ref.watch(entryTriggersProvider(entry.id)) ?? {};
    edges[entry.id] = triggeredIds;
  }
  return edges;
}

class EntriesGraph extends HookConsumerWidget {
  const EntriesGraph({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryIds = ref.watch(graphableEntryIdsProvider);
    final edges = ref.watch(triggerEdgesProvider);
    final currentPageEntries = ref.watch(graphableEntriesProvider);
    final currentPageEntryIds = currentPageEntries.map((entry) => entry.id).toSet();

    return DraggableGraph(
      entryIds: entryIds,
      edges: edges,
      currentPageEntryIds: currentPageEntryIds,
      emptyTitle: "There are no graphable entries on this page.",
      emptyButtonText: "Add Entry",
      onEmptyButtonPressed: () => ref.read(searchProvider.notifier).asBuilder()
        ..fetchNewEntry()
        ..nonGenericAddEntry()
        ..tag("trigger")
        ..open(),
    );
  }
}
