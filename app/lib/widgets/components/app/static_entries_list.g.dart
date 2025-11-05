// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'static_entries_list.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staticEntriesHash() => r'cb6c59ad4a6a57a2cceba227149a69ca750f6ec5';

/// See also [staticEntries].
@ProviderFor(staticEntries)
final staticEntriesProvider = AutoDisposeProvider<List<Entry>>.internal(
  staticEntries,
  name: r'staticEntriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staticEntriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaticEntriesRef = AutoDisposeProviderRef<List<Entry>>;
String _$staticEntryIdsHash() => r'67a3dd50a746bd2a4fb14c6fffbae2eed0400fde';

/// See also [staticEntryIds].
@ProviderFor(staticEntryIds)
final staticEntryIdsProvider = AutoDisposeProvider<List<String>>.internal(
  staticEntryIds,
  name: r'staticEntryIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staticEntryIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaticEntryIdsRef = AutoDisposeProviderRef<List<String>>;
String _$staticNodePositionHash() =>
    r'ddda227ab29590e7a0687a8e49b515ee3594c084';

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

/// See also [staticNodePosition].
@ProviderFor(staticNodePosition)
const staticNodePositionProvider = StaticNodePositionFamily();

/// See also [staticNodePosition].
class StaticNodePositionFamily extends Family<Offset> {
  /// See also [staticNodePosition].
  const StaticNodePositionFamily();

  /// See also [staticNodePosition].
  StaticNodePositionProvider call(
    String nodeId,
  ) {
    return StaticNodePositionProvider(
      nodeId,
    );
  }

  @override
  StaticNodePositionProvider getProviderOverride(
    covariant StaticNodePositionProvider provider,
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
  String? get name => r'staticNodePositionProvider';
}

/// See also [staticNodePosition].
class StaticNodePositionProvider extends AutoDisposeProvider<Offset> {
  /// See also [staticNodePosition].
  StaticNodePositionProvider(
    String nodeId,
  ) : this._internal(
          (ref) => staticNodePosition(
            ref as StaticNodePositionRef,
            nodeId,
          ),
          from: staticNodePositionProvider,
          name: r'staticNodePositionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$staticNodePositionHash,
          dependencies: StaticNodePositionFamily._dependencies,
          allTransitiveDependencies:
              StaticNodePositionFamily._allTransitiveDependencies,
          nodeId: nodeId,
        );

  StaticNodePositionProvider._internal(
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
    Offset Function(StaticNodePositionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StaticNodePositionProvider._internal(
        (ref) => create(ref as StaticNodePositionRef),
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
    return _StaticNodePositionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StaticNodePositionProvider && other.nodeId == nodeId;
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
mixin StaticNodePositionRef on AutoDisposeProviderRef<Offset> {
  /// The parameter `nodeId` of this provider.
  String get nodeId;
}

class _StaticNodePositionProviderElement
    extends AutoDisposeProviderElement<Offset> with StaticNodePositionRef {
  _StaticNodePositionProviderElement(super.provider);

  @override
  String get nodeId => (origin as StaticNodePositionProvider).nodeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
