import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// The two platform dialogs backups need, behind providers so the flows can
/// be tested without a phone.
class BackupPlatform {
  const BackupPlatform();

  /// The path of the file the owner picked, or null if they cancelled.
  Future<String?> pickBackupFile() async {
    final picked = await FilePicker.pickFile(type: FileType.any);
    return picked?.path;
  }

  Future<void> shareFile(String path, {required String message}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: message),
    );
  }
}

final backupPlatformProvider = Provider<BackupPlatform>(
  (ref) => const BackupPlatform(),
);
