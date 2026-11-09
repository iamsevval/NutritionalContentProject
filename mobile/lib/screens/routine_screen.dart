import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tüm rutinleri tutacağımız liste
  List<Map<String, dynamic>> _allRoutines = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _defaultRoutines = [
    {"id": "d1", "title": "Güne Su ile Başla", "desc": "1 büyük bardak limonlu su iç", "done": false, "time": "Sabah"},
    {"id": "d2", "title": "Lifli Kahvaltı", "desc": "Yulaf veya tam buğdaylı öğün", "done": false, "time": "Sabah"},
    {"id": "d3", "title": "10 Dakika Egzersiz", "desc": "Metabolizmayı hızlandır", "done": false, "time": "Sabah"},
    {"id": "d4", "title": "Yeşil Yapraklı Sebze", "desc": "Öğle yemeğine salata ekle", "done": false, "time": "Öğle"},
    {"id": "d5", "title": "Şekersiz İçecek", "desc": "Gazlı içecek yerine maden suyu", "done": false, "time": "Öğle"},
    {"id": "d6", "title": "Erken Akşam Yemeği", "desc": "Uyumadan 3 saat önce bitir", "done": false, "time": "Akşam"},
    {"id": "d7", "title": "Bitki Çayı", "desc": "Sindirimi rahatlatan Papatya/Rezene", "done": false, "time": "Akşam"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Uygulama ilk kez açılıyorsa veya rutinler boşsa varsayılanları yükle
    bool isFirstTime = prefs.getBool('routine_initialized') ?? false;
    List<String> savedItems = prefs.getStringList('routine_items') ?? [];

    if (!isFirstTime && savedItems.isEmpty) {
      // Varsayılanları kaydet
      savedItems = _defaultRoutines.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList('routine_items', savedItems);
      await prefs.setBool('routine_initialized', true);
    }

    // Günlük Sıfırlama Mantığı (Daily Reset Logic)
    String todayStr = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    String lastAccessDate = prefs.getString('routine_last_access_date') ?? todayStr;
    bool shouldReset = todayStr != lastAccessDate;
    
    if (shouldReset) {
      await prefs.setString('routine_last_access_date', todayStr);
    }

    List<Map<String, dynamic>> loadedRoutines = [];
    for (String itemStr in savedItems) {
      try {
        final Map<String, dynamic> item = jsonDecode(itemStr);
        // ID yoksa benzersiz bir ID ata (Eski eklenenler için)
        if (item['id'] == null) {
          item['id'] = DateTime.now().millisecondsSinceEpoch.toString() + item['title'].hashCode.toString();
        }
        
        // Eğer gün değiştiyse tamamlanma durumunu false yap
        if (shouldReset) {
          item['done'] = false;
        }
        
        loadedRoutines.add(item);
      } catch (e) {
        print("Rutin yüklenirken hata: $e");
      }
    }

    // Eğer reset yapıldıysa listeyi kalıcı olarak tekrar kaydet
    if (shouldReset) {
      List<String> strList = loadedRoutines.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList('routine_items', strList);
    }

    setState(() {
      _allRoutines = loadedRoutines;
      _isLoading = false;
    });
  }

  Future<void> _saveRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> strList = _allRoutines.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('routine_items', strList);
    
    // İlerleme güncellensin diye bugünün tarihini kaydedelim (Calendar okuyacak)
    // Actually Calendar calculates it automatically from routine_items. done.
  }

  void _showRoutineDialog({Map<String, dynamic>? existingItem}) {
    final bool isEditing = existingItem != null;
    
    TextEditingController titleController = TextEditingController(text: isEditing ? existingItem["title"] : "");
    TextEditingController descController = TextEditingController(text: isEditing ? existingItem["desc"] : "");
    String selectedTime = isEditing ? (existingItem["time"] ?? "Öğle") : "Öğle";

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isEditing ? "Rutini Düzenle" : "Yeni Rutin Ekle", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Rutin Adı",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: "Açıklama",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: selectedTime,
                      decoration: InputDecoration(
                        labelText: "Öğün",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      items: ["Sabah", "Öğle", "Akşam"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedTime = val!);
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("İptal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    
                    setState(() {
                      if (isEditing) {
                        final index = _allRoutines.indexWhere((r) => r["id"] == existingItem["id"]);
                        if (index != -1) {
                          _allRoutines[index]["title"] = titleController.text.trim();
                          _allRoutines[index]["desc"] = descController.text.trim();
                          _allRoutines[index]["time"] = selectedTime;
                        }
                      } else {
                        _allRoutines.add({
                          "id": DateTime.now().millisecondsSinceEpoch.toString(),
                          "title": titleController.text.trim(),
                          "desc": descController.text.trim(),
                          "done": false,
                          "time": selectedTime,
                          "isCustom": true
                        });
                      }
                    });
                    
                    await _saveRoutines();
                    if (!mounted) return;
                    Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? "Güncelle" : "Ekle"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _deleteRoutine(String id) async {
    setState(() {
      _allRoutines.removeWhere((item) => item["id"] == id);
    });
    await _saveRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beslenme Rutini"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: "Sabah"),
            Tab(text: "Öğle"),
            Tab(text: "Akşam"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildRoutineList("Sabah"),
              _buildRoutineList("Öğle"),
              _buildRoutineList("Akşam"),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () => _showRoutineDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRoutineList(String timeOfDay) {
    final list = _allRoutines.where((item) => item["time"] == timeOfDay).toList();
    
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("Bu öğün için rutin bulunamadı.", style: TextStyle(color: Colors.grey)),
          ],
        )
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final bool isDone = item["done"] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDone ? AppTheme.secondaryColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone ? AppTheme.primaryColor.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isDone,
                activeColor: AppTheme.successColor,
                onChanged: (val) async {
                  setState(() {
                    item["done"] = val!;
                  });
                  await _saveRoutines();
                },
              ),
              // Content
              Expanded(
                child: GestureDetector(
                  onTap: () => _showRoutineDialog(existingItem: item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        item["title"] ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDone ? AppTheme.primaryColor : AppTheme.darkTextColor,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["desc"] ?? "",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // Actions
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                onPressed: () => _showRoutineDialog(existingItem: item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor, size: 20),
                onPressed: () => _deleteRoutine(item["id"]),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
