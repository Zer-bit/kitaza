import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'activity_text.dart';
export 'failure_text.dart';
export 'generated/app_localizations.dart';
export 'guide_text.dart';
export 'health_text.dart';
export 'legal_text.dart';
export 'model_labels.dart';
export 'relative_day.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
