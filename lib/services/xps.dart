import 'dart:io';

/// Converts a PDF file to XPS using SumatraPDF + Microsoft XPS Document Writer.
/// Returns 0 for success, 1 for failure.
///
/// [pdfPath] is the full path to the input PDF.
/// [xpsPath] is the desired output XPS file path.
Future<String> convertPdfToXPS(String pdfPath, String xpsPath) async {
  try {
    // Ensure input exists
    if (!File(pdfPath).existsSync()) {
      return '1';
    }

    // Build the PowerShell command
    // -print-to flag selects the "Microsoft XPS Document Writer"
    // -print-to-file specifies the XPS output file.
    final command = '''
    Start-Process -FilePath "SumatraPDF.exe" `
      -ArgumentList '-print-to', 'Microsoft XPS Document Writer', '-print-to-file', '${xpsPath}', '${pdfPath}' `
      -NoNewWindow -Wait
    ''';

    final result = await Process.run(
      'powershell.exe',
      ['-Command', command],
      runInShell: true,
    );

    if (result.exitCode == 0 && File(xpsPath).existsSync()) {
      return 'xpsPath';
    } else {
      print("Error converting PDF: ${result.stderr}");
      return '1';
    }
  } catch (e) {
    print("Exception in convertPdfToXPS: $e");
    return '1';
  }
}

Future<int> convertPdfToXPS2(String pdfPath, String xpsPath) async {
  try {
    if (!File(pdfPath).existsSync()) {
      return 1;
    }

    // Absolute path to SumatraPDF.exe (adjust if bundled with your app)
    const sumatraPath = r'SumatraPDF.exe';

    // Build PowerShell script with explicit quoting
    final psCommand = '''
    Start-Process -FilePath "$sumatraPath" `
      -ArgumentList @(
        '-print-to', 'Microsoft XPS Document Writer',
        '-print-to-file', '${xpsPath}',
        '${pdfPath}'
      ) `
      -NoNewWindow -Wait
    ''';

    final result = await Process.run(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-Command', psCommand],
    );

    if (result.exitCode == 0 && File(xpsPath).existsSync()) {
      return 0;
    } else {
      print("Error converting PDF: ${result.stderr}\n${result.stdout}");
      return 1;
    }
  } catch (e) {
    print("Exception in convertPdfToXPS: $e");
    return 1;
  }
}

Future<int> convertPdfToXPS3(String pdfPath, String xpsPath) async {
  try {
    if (!File(pdfPath).existsSync()) return 1;

    // Path to SumatraPDF.exe (adjust if bundled)
    const sumatraExe = 'SumatraPDF.exe';

    final result = await Process.run(
      sumatraExe,
      [
        '-print-to',
        'Microsoft XPS Document Writer',
        xpsPath,
        pdfPath,
      ],
    );

    if (result.exitCode == 0 && File(xpsPath).existsSync()) {
      return 0;
    } else {
      print("Error: ${result.stderr}\n${result.stdout}");
      return 1;
    }
  } catch (e) {
    print("Exception in convertPdfToXPS: $e");
    return 1;
  }
}

Future<int> convertPdfToXPS4(String pdfPath, String xpsPath) async {
  try {
    if (!File(pdfPath).existsSync()) return 1;
// Path to SumatraPDF.exe (adjust if bundled)
    const sumatraExe = 'SumatraPDF.exe';
// Unique printer name
    const tempPrinterName = 'TempXPSConverter';
// Create port and printer using PowerShell (requires admin privileges)
    final createResult = await Process.run(
      'powershell',
      [
        '-Command',
        'Add-PrinterPort -Name "$xpsPath"; '
            'Add-Printer -Name "$tempPrinterName" -DriverName "Microsoft XPS Document Writer" -PortName "$xpsPath"',
      ],
    );
    if (createResult.exitCode != 0) {
      print(
          "Error creating printer: ${createResult.stderr}\n${createResult.stdout}");
      return 1;
    }
// Print using SumatraPDF to the temporary printer
    final printResult = await Process.run(
      sumatraExe,
      [
        '-print-to',
        tempPrinterName,
        '-silent',
        pdfPath,
      ],
    );
// Clean up the temporary printer and port
    final cleanupResult = await Process.run(
      'powershell',
      [
        '-Command',
        'Remove-Printer -Name "$tempPrinterName"; '
            'Remove-PrinterPort -Name "$xpsPath"',
      ],
    );
    if (cleanupResult.exitCode != 0) {
      print(
          "Error cleaning up: ${cleanupResult.stderr}\n${cleanupResult.stdout}");
    }
    if (printResult.exitCode == 0 && File(xpsPath).existsSync()) {
      return 0;
    } else {
      print("Error printing: ${printResult.stderr}\n${printResult.stdout}");
      return 1;
    }
  } catch (e) {
    print("Exception in convertPdfToXPS: $e");
    return 1;
  }
}

Future<int> convertPdfToXPS5(String pdfPath, String xpsPath) async {
  try {
    if (!File(pdfPath).existsSync()) return 1;

    // Path to Ghostscript executable (adjust if necessary, e.g., 'gswin64.exe' on Windows)
    const gsExe = 'gs.exe';

    final result = await Process.run(
      gsExe,
      [
        '-dNOPAUSE',
        '-dBATCH',
        '-sDEVICE=xpswrite',
        '-sOutputFile=$xpsPath',
        pdfPath,
      ],
    );

    if (result.exitCode == 0 && File(xpsPath).existsSync()) {
      return 0;
    } else {
      print("Error: ${result.stderr}\n${result.stdout}");
      return 1;
    }
  } catch (e) {
    print("Exception in convertPdfToXPS: $e");
    return 1;
  }
}

/// Prints an XPS file with the default printer on Windows.
/// Returns 0 for success, 1 for failure.
Future<int> printXpsFile(String xpsPath) async {
  try {
    if (!File(xpsPath).existsSync()) {
      return 1;
    }

    // Use PowerShell Start-Process with -Verb Print to send to default printer
    final command = '''
    Start-Process -FilePath '${xpsPath}' -Verb Print -PassThru | Wait-Process
    ''';

    final result = await Process.run(
      'powershell.exe',
      ['-Command', command],
      runInShell: true,
    );

    if (result.exitCode == 0) {
      return 0;
    } else {
      print("Error printing XPS: ${result.stderr}");
      return 1;
    }
  } catch (e) {
    print("Exception in printXpsFile: $e");
    return 1;
  }
}

Future<int> printPdfToDefaultPrinter(String pdfPath) async {
  print('printing pdfs');
  try {
    if (!File(pdfPath).existsSync()) return 1;

    const sumatraExe = 'SumatraPDF.exe';

    final result = await Process.run(
      sumatraExe,
      [
        '-print-to-default',
        '-print-settings',
        'noscale', // ensures actual size (no scaling)
        pdfPath,
      ],
    );

    if (result.exitCode == 0) {
      return 0;
    } else {
      print("Error: ${result.stderr}\n${result.stdout}");
      return 1;
    }
  } catch (e) {
    print("Exception in printPdfToDefaultPrinter: $e");
    return 1;
  }
}
