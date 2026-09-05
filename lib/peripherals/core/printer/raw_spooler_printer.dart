import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

/// PowerShell + inline C# (Win32 winspool.drv) helper that sends RAW bytes
/// directly to any installed Windows printer queue (USB / LPT / network /
/// IP-port-9100 backed). Bypasses driver dialogs and works fully silently.
const String _kRawSpoolerScript = r'''
param(
  [Parameter(Mandatory=$true)] [string]$PrinterName,
  [Parameter(Mandatory=$true)] [string]$FilePath
)

$ErrorActionPreference = "Stop"

$code = @'
using System;
using System.IO;
using System.Runtime.InteropServices;

public class RawPrinterHelper {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public class DOCINFOA {
        [MarshalAs(UnmanagedType.LPStr)] public string pDocName;
        [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile;
        [MarshalAs(UnmanagedType.LPStr)] public string pDataType;
    }

    [DllImport("winspool.Drv", EntryPoint="OpenPrinterA", SetLastError=true, CharSet=CharSet.Ansi, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool OpenPrinter([MarshalAs(UnmanagedType.LPStr)] string szPrinter, out IntPtr hPrinter, IntPtr pd);

    [DllImport("winspool.Drv", EntryPoint="ClosePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool ClosePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint="StartDocPrinterA", SetLastError=true, CharSet=CharSet.Ansi, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool StartDocPrinter(IntPtr hPrinter, Int32 level, [In, MarshalAs(UnmanagedType.LPStruct)] DOCINFOA di);

    [DllImport("winspool.Drv", EntryPoint="EndDocPrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool EndDocPrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint="StartPagePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool StartPagePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint="EndPagePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool EndPagePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint="WritePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, Int32 dwCount, out Int32 dwWritten);

    public static bool SendBytesToPrinter(string szPrinterName, byte[] bytes) {
        IntPtr hPrinter;
        DOCINFOA di = new DOCINFOA();
        di.pDocName = "PeripheralFrameworkRawJob";
        di.pDataType = "RAW";
        bool bSuccess = false;
        if (OpenPrinter(szPrinterName, out hPrinter, IntPtr.Zero)) {
            if (StartDocPrinter(hPrinter, 1, di)) {
                if (StartPagePrinter(hPrinter)) {
                    IntPtr pUnmanagedBytes = Marshal.AllocCoTaskMem(bytes.Length);
                    Marshal.Copy(bytes, 0, pUnmanagedBytes, bytes.Length);
                    int dwWritten = 0;
                    bSuccess = WritePrinter(hPrinter, pUnmanagedBytes, bytes.Length, out dwWritten);
                    Marshal.FreeCoTaskMem(pUnmanagedBytes);
                    EndPagePrinter(hPrinter);
                }
                EndDocPrinter(hPrinter);
            }
            ClosePrinter(hPrinter);
        }
        return bSuccess;
    }

    public static bool SendFileToPrinter(string szPrinterName, string szFileName) {
        FileStream fs = new FileStream(szFileName, FileMode.Open);
        BinaryReader br = new BinaryReader(fs);
        byte[] bytes = br.ReadBytes((int)fs.Length);
        bool result = SendBytesToPrinter(szPrinterName, bytes);
        br.Close();
        fs.Close();
        return result;
    }
}
'@

Add-Type -TypeDefinition $code -Language CSharp
$ok = [RawPrinterHelper]::SendFileToPrinter($PrinterName, $FilePath)
if (-not $ok) {
    Write-Error "WritePrinter returned false for printer: $PrinterName"
    exit 1
}
Write-Output "PRINTED"
''';

class RawSpoolerPrinter {
  RawSpoolerPrinter();

  final Lock _scriptLock = Lock();
  File? _cachedScriptFile;

  Future<File> _ensureScript() async {
    return _scriptLock.synchronized(() async {
      final cached = _cachedScriptFile;
      if (cached != null && await cached.exists()) {
        return cached;
      }
      final dir = await getTemporaryDirectory();
      final scriptPath = p.join(dir.path, 'pf_raw_print.ps1');
      final file = File(scriptPath);
      await file.writeAsString(_kRawSpoolerScript, flush: true);
      _cachedScriptFile = file;
      return file;
    });
  }

  Future<void> printBytes({
    required String printerName,
    required List<int> payload,
  }) async {
    if (printerName.trim().isEmpty) {
      throw ArgumentError('printerName is required');
    }
    if (payload.isEmpty) {
      throw ArgumentError('payload is empty');
    }

    final script = await _ensureScript();
    final tmpDir = await getTemporaryDirectory();
    final payloadFile = File(
      p.join(
        tmpDir.path,
        'pf_raw_payload_${DateTime.now().microsecondsSinceEpoch}.bin',
      ),
    );
    await payloadFile.writeAsBytes(payload, flush: true);

    try {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          script.path,
          '-PrinterName',
          printerName,
          '-FilePath',
          payloadFile.path,
        ],
      );
      if (result.exitCode != 0) {
        throw Exception(
          'Spooler print failed (exit ${result.exitCode}): '
          '${result.stderr.toString().trim()}',
        );
      }
    } finally {
      if (await payloadFile.exists()) {
        try {
          await payloadFile.delete();
        } catch (_) {}
      }
    }
  }
}
