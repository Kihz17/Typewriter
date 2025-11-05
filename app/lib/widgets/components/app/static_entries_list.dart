import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/widgets/components/app/draggable_graph.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";

part "static_entries_list.g.dart";

@riverpod
List<Entry> staticEntries(Ref ref) {
  final page = ref.watch(currentPageProvider);
  if (page == null) return [];

  return page.entries.where((entry) {
    final tags = ref.watch(entryBlueprintTagsProvider(entry.blueprintId));
    if (tags.isEmpty) {
      // Entries without a blueprint are always shown. So that the user can delete them.
      return true;
    }
    return tags.contains("static");
  }).toList();
}

@riverpod
List<String> staticEntryIds(Ref ref) {
  final currentPageEntries = ref.watch(staticEntriesProvider);
  return currentPageEntries.map((entry) => entry.id).toList();
}

@riverpod
Offset staticNodePosition(Ref ref, String nodeId) {
  final page = ref.watch(currentPageProvider);
  if (page == null) {
    debugPrint("Page was null when accessing position for node. This is a bug.");
    return Offset.zero;
  }

  return page.nodePositions[nodeId] ?? Offset.zero;
}

class StaticEntriesList extends HookConsumerWidget {
  const StaticEntriesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryIds = ref.watch(staticEntryIdsProvider);
    final currentPageEntries = ref.watch(staticEntriesProvider);
    final currentPageEntryIds = currentPageEntries.map((entry) => entry.id).toSet();

    return DraggableGraph(
      entryIds: entryIds,
      edges: {}, // Static entries have no edges/connections
      currentPageEntryIds: currentPageEntryIds,
      emptyTitle: "There are no static entries on this page.",
      emptyButtonText: "Add Entry",
      onEmptyButtonPressed: () => ref.read(searchProvider.notifier).asBuilder()
        ..fetchNewEntry()
        ..nonGenericAddEntry()
        ..tag("static", canRemove: false)
        ..open(),
    );
  }
}
