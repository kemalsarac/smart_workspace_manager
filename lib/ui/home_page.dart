import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_workspace_manager/core/process_manager.dart';
import 'package:smart_workspace_manager/core/profile_manager.dart';
import '../core/system_monitor.dart';
import '../models/system_stats.dart';
import 'mod_editor_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final monitor = SystemMonitor();
  SystemStats? stats;
  Map<String, bool> _hoverMap = {};
  List<String> mods = [];
  String? activeMod;

  @override
  void initState() {
    super.initState();
    _loadMods();

    Timer.periodic(const Duration(seconds: 1), (_) async {
      final newStats = await monitor.fetchStats();
      setState(() {
        stats = newStats;
      });
    });
  }

  Future<void> _loadMods() async {
    final profiles = await ProfileManager.loadProfiles();
    final newMods = profiles.keys.toSet().toList(); // benzersiz mod listesi
    setState(() {
      mods = newMods;
      for (var mod in newMods) {
        _hoverMap.putIfAbsent(mod, () => false); // sadece yoksa ekle
      }
      _hoverMap.putIfAbsent("Mod Ekle", () => false);
    });
  }

  Future<void> _activateMod(String modName) async {
    final profiles = await ProfileManager.loadProfiles();
    final profile = profiles[modName];
    if (profile == null) return;

    if (activeMod != null) await _deactivateMod(activeMod!);

    for (var p in List<String>.from(profile['close'] ?? [])) {
      ProcessManager.closeProgram(p);
    }
    for (var p in List<String>.from(profile['open'] ?? [])) {
      ProcessManager.openProgram(p);
    }

    setState(() => activeMod = modName);
  }

  Future<void> _deactivateMod(String modName) async {
    final profiles = await ProfileManager.loadProfiles();
    final profile = profiles[modName];
    if (profile == null) return;

    for (var p in List<String>.from(profile['open'] ?? [])) {
      ProcessManager.closeProgram(p);
    }

    setState(() {
      if (activeMod == modName) activeMod = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFf0f4f8), Color(0xFFd9e2ec)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Smart Workspace Manager",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 20),

              if (stats != null)
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: stats!.cpuUsage),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return _buildStatGraph("CPU", value, Colors.blueAccent);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: stats!.ramUsage),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return _buildStatGraph("RAM", value, Colors.green);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 2),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return _buildStatGraph("GPU", value, Colors.purple);
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rowCount = 4;
                    final itemWidth = (constraints.maxWidth - (16 * (rowCount - 1))) / rowCount;

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (var mod in mods)
                            SizedBox(
                              width: itemWidth,
                              child: _buildModCard(mod, Colors.blue.shade400, isAdd: false),
                            ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildModCard("Mod Ekle", Colors.green.shade400, isAdd: true),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatGraph(String name, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            minHeight: 12,
            color: color,
            backgroundColor: color.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 4),
        Text("${value.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildModCard(String modName, Color color, {required bool isAdd}) {
    bool isActive = activeMod == modName;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoverMap[modName] = true),
      onExit: (_) => setState(() => _hoverMap[modName] = false),
      child: AnimatedScale(
        scale: (_hoverMap[modName] ?? false) ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: () {
            if (isAdd) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModEditorPage()),
              ).then((value) => _loadMods());
            }
          },
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: isAdd
                  ? const LinearGradient(colors: [Color(0xFF00b09b), Color(0xFF96c93d)])
                  : LinearGradient(colors: [color.withOpacity(0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Stack(
              children: [
                Center(
                  child: isAdd
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, size: 32, color: Colors.white),
                            SizedBox(height: 6),
                            Text("Mod Ekle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        )
                      : Text(modName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                            Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)
                          ])),
                ),
                if (!isAdd)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(isActive ? Icons.stop_circle : Icons.play_circle_fill, size: 28, color: Colors.white),
                      onPressed: () async {
                        if (isActive) {
                          await _deactivateMod(modName);
                        } else {
                          await _activateMod(modName);
                        }
                      },
                    ),
                  ),
                if (!isAdd)
                  Positioned(
                    top: 8,
                    right: 36,
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 22, color: Colors.white),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ModEditorPage(modName: modName)),
                        );
                        if (result == true) _loadMods();
                      },
                    ),
                  ),
                if (!isAdd)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 22, color: Colors.redAccent),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Modu Sil"),
                            content: Text("“$modName” modunu silmek istediğine emin misin?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sil")),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ProfileManager.deleteProfile(modName);
                          _loadMods();
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}