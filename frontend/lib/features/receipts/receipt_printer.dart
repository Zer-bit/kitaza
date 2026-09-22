import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../core/storage/preferences_store.dart';
import 'receipt_layout.dart';

class PrinterDevice {
  const PrinterDevice({required this.name, required this.address});

  final String name;
  final String address;
}

/// What happened when printing, so each failure gets its own plain advice.
enum PrintOutcome {
  printed,
  bluetoothOff,
  noPermission,
  couldNotConnect,
  failedToSend,
}

/// Sends bytes to a paired Bluetooth thermal printer. Behind a provider so
/// the receipt screens can be tested without a printer.
class ReceiptPrinter {
  const ReceiptPrinter();

  Future<List<PrinterDevice>> pairedPrinters() async {
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map(
          (device) =>
              PrinterDevice(name: device.name, address: device.macAdress),
        )
        .toList(growable: false);
  }

  /// Connects, prints and disconnects every time. Holding the connection open
  /// would be faster, but a cheap printer that goes to sleep holding a stale
  /// connection is the most common "it stopped printing" complaint.
  Future<PrintOutcome> printBytes(String address, List<int> bytes) async {
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      return PrintOutcome.bluetoothOff;
    }
    if (!await PrintBluetoothThermal.isPermissionBluetoothGranted) {
      return PrintOutcome.noPermission;
    }
    if (!await PrintBluetoothThermal.connect(macPrinterAddress: address)) {
      return PrintOutcome.couldNotConnect;
    }

    try {
      final sent = await PrintBluetoothThermal.writeBytes(bytes);
      return sent ? PrintOutcome.printed : PrintOutcome.failedToSend;
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }
}

final receiptPrinterProvider = Provider<ReceiptPrinter>(
  (ref) => const ReceiptPrinter(),
);

/// The printer this phone uses, remembered between launches.
class PrinterSettings {
  const PrinterSettings({
    this.address,
    this.name,
    this.paper = PaperWidth.mm58,
  });

  final String? address;
  final String? name;
  final PaperWidth paper;

  bool get isChosen => address != null;
}

class PrinterSettingsController extends Notifier<PrinterSettings> {
  @override
  PrinterSettings build() {
    final prefs = ref.read(preferencesStoreProvider);
    return PrinterSettings(
      address: prefs.readPrinterAddress(),
      name: prefs.readPrinterName(),
      paper: PaperWidth.parse(prefs.readPrinterPaper()),
    );
  }

  Future<void> choose(PrinterDevice device) async {
    state = PrinterSettings(
      address: device.address,
      name: device.name,
      paper: state.paper,
    );
    final prefs = ref.read(preferencesStoreProvider);
    await prefs.writePrinterAddress(device.address);
    await prefs.writePrinterName(device.name);
  }

  Future<void> setPaper(PaperWidth paper) async {
    state = PrinterSettings(
      address: state.address,
      name: state.name,
      paper: paper,
    );
    await ref.read(preferencesStoreProvider).writePrinterPaper(paper.name);
  }
}

final printerSettingsProvider =
    NotifierProvider<PrinterSettingsController, PrinterSettings>(
      PrinterSettingsController.new,
    );
