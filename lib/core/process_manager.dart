import 'dart:io';
import 'package:file_picker/file_picker.dart';
class ProcessManager {
  static void closeProgram(String processName) {
    try {
      // Windows taskkill komutu
      Process.run(
        'taskkill',
        ['/IM', '$processName.exe', '/F'],
        runInShell: true,
      ).then((result) {
        print('Kapatıldı: $processName => ${result.stdout}');
      });
    } catch (e) {
      print('Hata kapatırken: $processName => $e');
    }
  }

  /// Uygulamayı açar
  static void openProgram(String path) {
    try {
      Process.start(path, [], runInShell: true);
    } catch (e) {
      print('Hata açarken: $path => $e');
    }
  }
 static Future<String?> pickProgram() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.first.path;
    }
    return null;
  }

}