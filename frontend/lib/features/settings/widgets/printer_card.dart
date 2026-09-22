import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/feedback_messenger.dart';
import '../../receipts/escpos_encoder.dart';
import '../../receipts/receipt_layout.dart';
import '../../receipts/receipt_printer.dart';
import '../../receipts/receipt_sheet.dart';

class PrinterCard extends ConsumerWidget {
  const PrinterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(printerSettingsProvider);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: Text(l10n.printerSection),
            subtitle: Text(settings.name ?? l10n.printerNone),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _choose(context, ref),
          ),
          const Divider(height: 1),
          Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Expanded(child: Text(l10n.printerPaper)),
                SegmentedButton<PaperWidth>(
                  segments: const [
                    ButtonSegment(value: PaperWidth.mm58, label: Text('58 mm')),
                    ButtonSegment(value: PaperWidth.mm80, label: Text('80 mm')),
                  ],
                  selected: {settings.paper},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => ref
                      .read(printerSettingsProvider.notifier)
                      .setPaper(selection.first),
                ),
              ],
            ),
          ),
          if (settings.isChosen) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(l10n.printerTest),
              onTap: () => _testPrint(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final devices = await ref.read(receiptPrinterProvider).pairedPrinters();
    if (!context.mounted) return;

    if (devices.isEmpty) {
      FeedbackMessenger.warn(context, l10n.printerNoneFound);
      return;
    }

    final chosen = await showDialog<PrinterDevice>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.printerChoose),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              l10n.printerChooseHint,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ),
          for (final device in devices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, device),
              child: ListTile(
                leading: const Icon(Icons.bluetooth_rounded),
                title: Text(device.name),
                subtitle: Text(device.address),
              ),
            ),
        ],
      ),
    );

    if (chosen != null) {
      await ref.read(printerSettingsProvider.notifier).choose(chosen);
    }
  }

  Future<void> _testPrint(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final settings = ref.read(printerSettingsProvider);
    final bytes = EscPosEncoder.encode([
      ReceiptLine(
        l10n.appName,
        align: ReceiptAlign.center,
        bold: true,
        large: true,
      ),
      ReceiptLine(l10n.printerTestLine),
      ReceiptLine('-' * settings.paper.columns),
    ]);

    final outcome = await ref
        .read(receiptPrinterProvider)
        .printBytes(settings.address!, bytes);
    if (!context.mounted) return;
    if (outcome == PrintOutcome.printed) {
      FeedbackMessenger.success(context, l10n.receiptPrinted);
    } else {
      FeedbackMessenger.error(context, describePrintOutcome(outcome, l10n));
    }
  }
}
