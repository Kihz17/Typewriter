// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentPageIdHash() => r'9442a56c441884a942b6a28d352693b7832793b5';

/// See also [currentPageId].
@ProviderFor(currentPageId)
final currentPageIdProvider = Provider<String?>.internal(
  currentPageId,
  name: r'currentPageIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentPageIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentPageIdRef = ProviderRef<String?>;
String _$trackPageCleanupHash() => r'4c5ca394a7ec1115c2c3d6e145093449a2cb5617';

/// See also [_trackPageCleanup].
@ProviderFor(_trackPageCleanup)
final _trackPageCleanupProvider = AutoDisposeProvider<void>.internal(
  _trackPageCleanup,
  name: r'_trackPageCleanupProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trackPageCleanupHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef _TrackPageCleanupRef = AutoDisposeProviderRef<void>;
String _$cleanupPageProvidersHash() =>
    r'5bb4f367300619b11cf27d54793a500e71161b7b';

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

/// See also [cleanupPageProviders].
@ProviderFor(cleanupPageProviders)
const cleanupPageProvidersProvider = CleanupPageProvidersFamily();

/// See also [cleanupPageProviders].
class CleanupPageProvidersFamily extends Family<void> {
  /// See also [cleanupPageProviders].
  const CleanupPageProvidersFamily();

  /// See also [cleanupPageProviders].
  CleanupPageProvidersProvider call(
    String? previousPageId,
  ) {
    return CleanupPageProvidersProvider(
      previousPageId,
    );
  }

  @override
  CleanupPageProvidersProvider getProviderOverride(
    covariant CleanupPageProvidersProvider provider,
  ) {
    return call(
      provider.previousPageId,
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
  String? get name => r'cleanupPageProvidersProvider';
}

/// See also [cleanupPageProviders].
class CleanupPageProvidersProvider extends AutoDisposeProvider<void> {
  /// See also [cleanupPageProviders].
  CleanupPageProvidersProvider(
    String? previousPageId,
  ) : this._internal(
          (ref) => cleanupPageProviders(
            ref as CleanupPageProvidersRef,
            previousPageId,
          ),
          from: cleanupPageProvidersProvider,
          name: r'cleanupPageProvidersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$cleanupPageProvidersHash,
          dependencies: CleanupPageProvidersFamily._dependencies,
          allTransitiveDependencies:
              CleanupPageProvidersFamily._allTransitiveDependencies,
          previousPageId: previousPageId,
        );

  CleanupPageProvidersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.previousPageId,
  }) : super.internal();

  final String? previousPageId;

  @override
  Override overrideWith(
    void Function(CleanupPageProvidersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CleanupPageProvidersProvider._internal(
        (ref) => create(ref as CleanupPageProvidersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        previousPageId: previousPageId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<void> createElement() {
    return _CleanupPageProvidersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CleanupPageProvidersProvider &&
        other.previousPageId == previousPageId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, previousPageId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CleanupPageProvidersRef on AutoDisposeProviderRef<void> {
  /// The parameter `previousPageId` of this provider.
  String? get previousPageId;
}

class _CleanupPageProvidersProviderElement
    extends AutoDisposeProviderElement<void> with CleanupPageProvidersRef {
  _CleanupPageProvidersProviderElement(super.provider);

  @override
  String? get previousPageId =>
      (origin as CleanupPageProvidersProvider).previousPageId;
}

String _$currentPageLabelHash() => r'5555a842f854d2bb41328655fb41c9387f7c4902';

/// See also [currentPageLabel].
@ProviderFor(currentPageLabel)
final currentPageLabelProvider = AutoDisposeProvider<String>.internal(
  currentPageLabel,
  name: r'currentPageLabelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentPageLabelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentPageLabelRef = AutoDisposeProviderRef<String>;
String _$currentPageHash() => r'ca655b0b587ace37449e3ce57022c1a8ad9c0184';

/// See also [currentPage].
@ProviderFor(currentPage)
final currentPageProvider = AutoDisposeProvider<Page?>.internal(
  currentPage,
  name: r'currentPageProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentPageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentPageRef = AutoDisposeProviderRef<Page?>;
String _$currentPageTypeHash() => r'cc67b9a56c7abe2e82a90687ad1d87f1ea7a8e1c';

/// See also [currentPageType].
@ProviderFor(currentPageType)
final currentPageTypeProvider = AutoDisposeProvider<PageType?>.internal(
  currentPageType,
  name: r'currentPageTypeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentPageTypeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentPageTypeRef = AutoDisposeProviderRef<PageType?>;
String _$writersHash() => r'eb8dad235050807b77379f0644b5cd9e2b67db75';

/// See also [_writers].
@ProviderFor(_writers)
final _writersProvider = AutoDisposeProvider<List<Writer>>.internal(
  _writers,
  name: r'_writersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$writersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef _WritersRef = AutoDisposeProviderRef<List<Writer>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
