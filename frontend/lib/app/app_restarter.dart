import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import 'app_bootstrap.dart';

/// Rebuilds the whole app from fresh dependencies, as if it had just been
/// launched.
///
/// Restoring a backup replaces the database file itself. Every provider still
/// holds the old connection, so rather than patching each one the app is
/// brought up again from scratch: close, swap the file, reopen, rebuild.
class AppRestarter extends StatefulWidget {
  const AppRestarter({super.key, required this.initial, required this.builder});

  final AppDependencies initial;
  final Widget Function(AppDependencies dependencies) builder;

  /// [whileClosed] runs after the database is closed and before it reopens -
  /// the only safe moment to replace the file.
  static Future<void> restart(
    BuildContext context, {
    Future<void> Function(AppDependencies closing)? whileClosed,
  }) {
    final state = context.findAncestorStateOfType<_AppRestarterState>();
    if (state == null) throw StateError('AppRestarter is not in the tree');
    return state._restart(whileClosed);
  }

  @override
  State<AppRestarter> createState() => _AppRestarterState();
}

class _AppRestarterState extends State<AppRestarter> {
  late AppDependencies _dependencies = widget.initial;
  Key _generation = UniqueKey();
  bool _restarting = false;

  Future<void> _restart(
    Future<void> Function(AppDependencies closing)? whileClosed,
  ) async {
    final closing = _dependencies;
    setState(() => _restarting = true);

    await closing.database.db.close();
    await whileClosed?.call(closing);
    final fresh = await loadAppDependencies();

    if (!mounted) return;
    setState(() {
      _dependencies = fresh;
      _generation = UniqueKey();
      _restarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_restarting) return const _RestartingView();

    return KeyedSubtree(key: _generation, child: widget.builder(_dependencies));
  }
}

/// Shown for the moment the app is being brought back up. Deliberately free
/// of providers and translations, neither of which exist at this point.
class _RestartingView extends StatelessWidget {
  const _RestartingView();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: AppPalette.canvasLight,
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppPalette.teal,
            ),
          ),
        ),
      ),
    );
  }
}
