import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_workspace_manager/core/profile_manager.dart';
import 'package:smart_workspace_manager/core/process_manager.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_workspace_manager/core/profile_manager.dart';
import 'package:smart_workspace_manager/core/process_manager.dart';

class ModEditorPage extends StatefulWidget {
  final String? modName; // Düzenleme için mevcut mod adı
  const ModEditorPage({super.key, this.modName});

  @override
  State<ModEditorPage> createState() => _ModEditorPageState();
}

class _ModEditorPageState extends State<ModEditorPage> {
  List<String> runningProcesses = [];
  List<String> selectedToClose = [];
  List<String> selectedToOpen = [];
  TextEditingController modNameController = TextEditingController();
  bool loadingProcesses = true;

  @override
@override
void initState() {
  super.initState();

  // 👇 SADECE GÖRSEL İÇİN BURAYA EKLE
  selectedToOpen.add("C:\\Program Files (x86)\\Steam\\steamapps\\common\\Lossless Scaling\\LosslessScaling.exe");
  selectedToOpen.add("C:\\Desktop\\Midnightcs2.exe");

  if (widget.modName != null) {
    modNameController.text = widget.modName!;
    _loadExistingMod(widget.modName!);
  }

  _loadRunningProcesses();
}

  Future<void> _loadExistingMod(String modName) async {
    final profiles = await ProfileManager.loadProfiles();
    final profile = profiles[modName];
    if (profile != null) {
      setState(() {
        selectedToClose = List<String>.from(profile['close'] ?? []);
        selectedToOpen = List<String>.from(profile['open'] ?? []);
      });
    }
  }

  Future<void> _loadRunningProcesses() async {
    setState(() => loadingProcesses = true);

    final blockedProcesses = {
      'system', 'idle', 'csrss', 'wininit', 'winlogon',
      'smss', 'services', 'lsass', 'explorer', 'dwm',
      'taskhostw', 'sihost', 'spoolsv',
    };

    try {
      final result = await Process.run(
        'powershell',
        ['Get-Process | Select-Object -ExpandProperty Name'],
        runInShell: true,
      );

      final lines = result.stdout.toString().split('\n');
      List<String> processes = [];
      for (var line in lines) {
        line = line.trim().toLowerCase();
        if (line.isEmpty) continue;
        if (blockedProcesses.contains(line)) continue;
        if (!processes.contains(line)) processes.add(line);
      }

      setState(() {
        runningProcesses = processes;
        loadingProcesses = false;
      });
    } catch (e) {
      setState(() {
        runningProcesses = [];
        loadingProcesses = false;
      });
    }
  }

  Future<void> _saveMod() async {
    final name = modNameController.text.trim();
    if (name.isEmpty) return;

    final profiles = await ProfileManager.loadProfiles();
    profiles[name] = {
      'open': selectedToOpen,
      'close': selectedToClose,
    };
    await ProfileManager.saveProfiles(profiles);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modName != null ? "Mod Düzenle" : "Yeni Mod Oluştur"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: modNameController,
              decoration: const InputDecoration(
                labelText: "Mod Adı",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
child: Row(
  children: [
    // Kapatılacak uygulamalar
  Expanded(
  child: loadingProcesses
      ? const Center(child: CircularProgressIndicator())
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kapatılacak Uygulamalar",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: [
                  ...selectedToClose,
                  ...runningProcesses.where((p) => !selectedToClose.contains(p))
                ].length,
                itemBuilder: (context, index) {
                  final displayedProcesses = [
                    ...selectedToClose,
                    ...runningProcesses.where((p) => !selectedToClose.contains(p))
                  ];
                  final process = displayedProcesses[index];
                  final selected = selectedToClose.contains(process);

                  return CheckboxListTile(
                    title: Text(process),
                    value: selected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (!selectedToClose.contains(process)) selectedToClose.add(process);
                        } else {
                          selectedToClose.remove(process);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
),
                  const SizedBox(width: 16),
                  // Açılacak uygulamalar
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Açılacak Uygulamalar",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: selectedToOpen.length,
                              itemBuilder: (context, index) {
                                final prog = selectedToOpen[index];
                                return ListTile(
                                  title: Text(prog),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      setState(() {
                                        selectedToOpen.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Program Ekle"),
                            onPressed: () async {
                              final result = await ProcessManager.pickProgram();
                              if (result != null) {
                                setState(() {
                                  
                                  if (!selectedToOpen.contains(result)) selectedToOpen.add(result);
                                });
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveMod,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size.fromHeight(50)),
              child: const Text(
                "Modu Kaydet",
                style: TextStyle(fontSize: 18,color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}