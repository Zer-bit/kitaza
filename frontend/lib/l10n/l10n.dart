import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'failure_text.dart';
export 'generated/app_localizations.dart';
export 'health_text.dart';
export 'model_labels.dart';
export 'relative_day.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
