import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/repositories/store_scope.dart';
import '../../l10n/l10n.dart';

/// One place that decides how loading and failure look, so every screen
/// handles them the same way.
///
/// When data is being fetched again - after a sale, a sync, a new period, a
/// letter typed into search - what is already on screen stays there and is
/// replaced in place. Swapping it for a spinner and back made the screen
/// blink on every change. The spinner is only for the first load.
///
/// The one exception is a change of store. Every figure in the app belongs to
/// a store, and the new store's name must never sit above the old store's
/// takings, even for a moment, so a store switch starts from a spinner.
class AsyncContent<T> extends ConsumerStatefulWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  ConsumerState<AsyncContent<T>> createState() => _AsyncContentState<T>();
}

class _AsyncContentState<T> extends ConsumerState<AsyncContent<T>> {
  /// Which store each result came from, for as long as the result exists.
  ///
  /// Kept beside the result rather than in this widget, because a tab's
  /// result outlives its screen: opening the tab again finds last visit's
  /// figures still loaded, and needs to know whose they are.
  static final Expando<String> _storeOf = Expando('store the result is from');

  /// The last result this widget saw arrive, so a rebuild with the same one
  /// is not mistaken for a new one.
  AsyncValue<T>? _lastArrived;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(activeStoreIdProvider);
    final value = widget.value;
    final data = value.hasValue ? value.value : null;

    // A result is from whichever store was active when it arrived. Tagged on
    // arrival only: a rebuild caused by a store switch still carries the old
    // store's result, and must not relabel it as the new store's.
    if (!value.isLoading && !identical(value, _lastArrived)) {
      _lastArrived = value;
      _tag(data, store);
    }

    final failed = value.hasError && !value.isLoading;
    final showsData =
        value.hasValue &&
        !failed &&
        _isFrom(data, store, arrived: !value.isLoading);

    // Keyed by store so a switch is a cut, not a fade: an ordinary change
    // cross-fades, but fading out keeps the old child on screen, and the old
    // child here would be the last store's figures under the new store's name.
    return AnimatedSwitcher(
      key: ValueKey(store),
      duration: AppMotion.standard,
      switchInCurve: AppMotion.easing,
      child: showsData
          ? KeyedSubtree(
              key: const ValueKey('data'),
              child: widget.builder(value.requireValue),
            )
          : failed
          ? _FailureView(
              key: const ValueKey('error'),
              message: context.l10n.failure(value.error!),
              onRetry: widget.onRetry,
            )
          : const Center(
              key: ValueKey('loading'),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
    );
  }

  void _tag(Object? data, String store) {
    if (_canCarryTag(data)) _storeOf[data!] = store;
  }

  /// Whether [data] belongs to [store]. A result that cannot carry a tag is
  /// trusted once it has arrived and not before; no screen loads one today.
  bool _isFrom(Object? data, String store, {required bool arrived}) =>
      _canCarryTag(data) ? _storeOf[data!] == store : arrived;

  /// Numbers, strings, booleans, records and null cannot hold a tag.
  static bool _canCarryTag(Object? data) =>
      data != null &&
      data is! num &&
      data is! String &&
      data is! bool &&
      data is! Record;
}

class _FailureView extends StatelessWidget {
  const _FailureView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.gapMd,
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapLg,
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.commonTryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
