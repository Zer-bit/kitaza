import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/sale.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/feedback_messenger.dart';
import '../authentication/auth_controller.dart';
import 'escpos_encoder.dart';
import 'receipt_layout.dart';
import 'receipt_printer.dart';

/// A sale's receipt as it will look, with the two ways to hand it over.
class ReceiptSheet extends ConsumerWidget {
  const ReceiptSheet({super.key, required this.sale});

  final Sale sale;

  static Future<void> show(BuildContext context, Sale sale) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReceiptSheet(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final paper = ref.watch(printerSettingsProvider).paper;
    final store = ref.watch(currentSessionProvider)?.store.name ?? l10n.appName;
    final text = ReceiptLayout(
      l10n: l10n,
      width: paper,
    ).asText(sale: sale, storeName: store);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(l10n.receiptTitle, style: theme.textTheme.titleLarge),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: AppRadius.fieldAll,
                ),
                // Horizontal scroll so a 48-column receipt never wraps on a
                // narrow phone and misleads about how it will print.
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          SharePlus.instance.share(ShareParams(text: text)),
                      icon: const Icon(Icons.share_rounded),
                      label: Text(l10n.receiptShare),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _print(context, ref, store),
                      icon: const Icon(Icons.print_rounded),
                      label: Text(l10n.receiptPrint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _print(BuildContext context, WidgetRef ref, String store) async {
    final l10n = context.l10n;
    final printer = ref.read(printerSettingsProvider);
    if (!printer.isChosen) {
      FeedbackMessenger.warn(context, l10n.receiptNoPrinter);
      return;
    }

    final bytes = EscPosEncoder.encode(
      ReceiptLayout(
        l10n: l10n,
        width: printer.paper,
        currencySymbol: 'P',
      ).build(sale: sale, storeName: store),
    );
    final outcome = await ref
        .read(receiptPrinterProvider)
        .printBytes(printer.address!, bytes);
    if (!context.mounted) return;

    if (outcome == PrintOutcome.printed) {
      FeedbackMessenger.success(context, l10n.receiptPrinted);
    } else {
      FeedbackMessenger.error(context, describePrintOutcome(outcome, l10n));
    }
  }
}

String describePrintOutcome(PrintOutcome outcome, AppLocalizations l10n) =>
    switch (outcome) {
      PrintOutcome.printed => l10n.receiptPrinted,
      PrintOutcome.bluetoothOff => l10n.printerBluetoothOff,
      PrintOutcome.noPermission => l10n.printerNoPermission,
      PrintOutcome.couldNotConnect => l10n.printerCouldNotConnect,
      PrintOutcome.failedToSend => l10n.printerFailed,
    };
