// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$manifestEntriesHash() => r'a6574b7ac3e5e6d5c11cc005f907ec1e52bc2b16';

/// See also [manifestEntries].
@ProviderFor(manifestEntries)
final manifestEntriesProvider = AutoDisposeProvider<List<Entry>>.internal(
  manifestEntries,
  name: r'manifestEntriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$manifestEntriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ManifestEntriesRef = AutoDisposeProviderRef<List<Entry>>;
String _$manifestEntryIdsHash() => r'f992a43c8447c0f26bd7f02277eb8080233d4232';

/// See also [manifestEntryIds].
@ProviderFor(manifestEntryIds)
final manifestEntryIdsProvider = AutoDisposeProvider<List<String>>.internal(
  manifestEntryIds,
  name: r'manifestEntryIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$manifestEntryIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ManifestEntryIdsRef = AutoDisposeProviderRef<List<String>>;
String _$entryReferencesHash() => r'ee4cd980835d93b915ef1fcc6ab625c2ac4fd6f8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [entryReferences].
@ProviderFor(entryReferences)
const entryReferencesProvider = EntryReferencesFamily();

/// See also [entryReferences].
class EntryReferencesFamily extends Family<Set<String>?> {
  /// See also [entryReferences].
  const EntryReferencesFamily();

  /// See also [entryReferences].
  EntryReferencesProvider call(
    String entryId,
  ) {
    return EntryReferencesProvider(
      entryId,
    );
  }

  @override
  EntryReferencesProvider getProviderOverride(
    covariant EntryReferencesProvider provider,
  ) {
    return call(
      provider.entryId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'entryReferencesProvider';
}

/// See also [entryReferences].
class EntryReferencesProvider extends AutoDisposeProvider<Set<String>?> {
  /// See also [entryReferences].
  EntryReferencesProvider(
    String entryId,
  ) : this._internal(
          (ref) => entryReferences(
            ref as EntryReferencesRef,
            entryId,
          ),
          from: entryReferencesProvider,
          name: r'entryReferencesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$entryReferencesHash,
          dependencies: EntryReferencesFamily._dependencies,
          allTransitiveDependencies:
              EntryReferencesFamily._allTransitiveDependencies,
          entryId: entryId,
        );

  EntryReferencesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.entryId,
  }) : super.internal();

  final String entryId;

  @override
  Override overrideWith(
    Set<String>? Function(EntryReferencesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntryReferencesProvider._internal(
        (ref) => create(ref as EntryReferencesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        entryId: entryId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Set<String>?> createElement() {
    return _EntryReferencesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryReferencesProvider && other.entryId == entryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, entryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EntryReferencesRef on AutoDisposeProviderRef<Set<String>?> {
  /// The parameter `entryId` of this provider.
  String get entryId;
}

class _EntryReferencesProviderElement
    extends AutoDisposeProviderElement<Set<String>?> with EntryReferencesRef {
  _EntryReferencesProviderElement(super.provider);

  @override
  String get entryId => (origin as EntryReferencesProvider).entryId;
}

String _$manifestNodePositionHash() =>
    r'159a2ece2027f9a34878fea8ecf756857033c734';

/// See also [manifestNodePosition].
@ProviderFor(manifestNodePosition)
const manifestNodePositionProvider = ManifestNodePositionFamily();

/// See also [manifestNodePosition].
class ManifestNodePositionFamily extends Family<Offset> {
  /// See also [manifestNodePosition].
  const ManifestNodePositionFamily();

  /// See also [manifestNodePosition].
  ManifestNodePositionProvider call(
    String nodeId,
  ) {
    return ManifestNodePositionProvider(
      nodeId,
    );
  }

  @override
  ManifestNodePositionProvider getProviderOverride(
    covariant ManifestNodePositionProvider provider,
  ) {
    return call(
      provider.nodeId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'manifestNodePositionProvider';
}

/// See also [manifestNodePosition].
class ManifestNodePositionProvider extends AutoDisposeProvider<Offset> {
  /// See also [manifestNodePosition].
  ManifestNodePositionProvider(
    String nodeId,
  ) : this._internal(
          (ref) => manifestNodePosition(
            ref as ManifestNodePositionRef,
            nodeId,
          ),
          from: manifestNodePositionProvider,
          name: r'manifestNodePositionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$manifestNodePositionHash,
          dependencies: ManifestNodePositionFamily._dependencies,
          allTransitiveDependencies:
              ManifestNodePositionFamily._allTransitiveDependencies,
          nodeId: nodeId,
        );

  ManifestNodePositionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.nodeId,
  }) : super.internal();

  final String nodeId;

  @override
  Override overrideWith(
    Offset Function(ManifestNodePositionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ManifestNodePositionProvider._internal(
        (ref) => create(ref as ManifestNodePositionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        nodeId: nodeId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Offset> createElement() {
    return _ManifestNodePositionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ManifestNodePositionProvider && other.nodeId == nodeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, nodeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ManifestNodePositionRef on AutoDisposeProviderRef<Offset> {
  /// The parameter `nodeId` of this provider.
  String get nodeId;
}

class _ManifestNodePositionProviderElement
    extends AutoDisposeProviderElement<Offset> with ManifestNodePositionRef {
  _ManifestNodePositionProviderElement(super.provider);

  @override
  String get nodeId => (origin as ManifestNodePositionProvider).nodeId;
}

String _$manifestEdgesHash() => r'a1962539f1f396134dace3e0803e51e1ae152b43';

/// See also [manifestEdges].
@ProviderFor(manifestEdges)
final manifestEdgesProvider =
    AutoDisposeProvider<Map<String, Set<String>>>.internal(
  manifestEdges,
  name: r'manifestEdgesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$manifestEdgesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ManifestEdgesRef = AutoDisposeProviderRef<Map<String, Set<String>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
