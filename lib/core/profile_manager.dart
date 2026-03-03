import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class ProfileManager {
  static final String _profilesFile =
      path.join(Directory.current.path, 'profiles.json');

  /// JSON'dan profilleri yükler
  static Future<Map<String, dynamic>> loadProfiles() async {
    final file = File(_profilesFile);
    if (!await file.exists()) {
      await file.writeAsString(jsonEncode({}));
      return {};
    }
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Profilleri kaydeder
  static Future<void> saveProfiles(Map<String, dynamic> profiles) async {
    final file = File(_profilesFile);
    await file.writeAsString(jsonEncode(profiles));
  }

  /// Belirli bir modu sil
  static Future<void> deleteProfile(String modName) async {
    final profiles = await loadProfiles();
    profiles.remove(modName);
    await saveProfiles(profiles);
  }
}