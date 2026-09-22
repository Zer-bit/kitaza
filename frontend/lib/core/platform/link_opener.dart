import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a page outside the app: the payment page, which must run in a real
/// browser where GCash and Maya can hand back to it.
class LinkOpener {
  const LinkOpener();

  Future<bool> open(Uri link) async {
    try {
      return await launchUrl(link, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

final linkOpenerProvider = Provider<LinkOpener>((ref) => const LinkOpener());
