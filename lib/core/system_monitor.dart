import 'dart:io';

import '../models/system_stats.dart';

class SystemMonitor {
  Future<SystemStats> fetchStats() async {
    final cpu = await getCpuUsage();
    final ram = await getRamUsage();
    return SystemStats(cpuUsage: cpu, ramUsage: ram);
  }

Future<double> getCpuUsage() async {
  try {
    final result = await Process.run(
      'powershell',
      [
        '-Command',
        r"(Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average"
      ],
    );
    final output = result.stdout.toString().trim();
    final match = RegExp(r'[\d\.]+').firstMatch(output);
    if (match != null) {
      return double.parse(match.group(0)!);
    } else {
      return 0;
    }
  } catch (e) {
    print("CPU fetch error: $e");
    return 0;
  }
}

Future<double> getRamUsage() async {
  try {
    final result = await Process.run(
      'powershell',
      [
        '-Command',
        r"$os = Get-CimInstance Win32_OperatingSystem; (($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/$os.TotalVisibleMemorySize)*100"
      ],
    );

    // Ham çıktıyı temizle
    final output = result.stdout.toString().trim();

    // Rakamı parse et
    final match = RegExp(r'[\d\.]+').firstMatch(output);
    if (match != null) {
      return double.parse(match.group(0)!);
    } else {
      return 0;
    }
  } catch (e) {
    print("RAM fetch error: $e");
    return 0;
  }
}
}