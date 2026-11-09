import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/allergen_badge.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    // API'den gelen veriyi çözümle
    final data = resultData['data'] ?? {};
    final String source = resultData['source'] ?? 'Bilinmiyor';
    
    final icerikler = (data['icerikler_tablosu'] as List?) ?? [];
    final besinler = (data['besinler'] as Map?) ?? {};
    final alerjenler = (data['alerjenler'] as List?) ?? [];
    final saglikPuani = data['saglik_puani'];
    final saglikYorumu = data['saglik_yorumu'] ?? '';
    
    // Güvenlik uyarısı
    final bool isSafe = data['is_safe'] ?? true;
    final List<dynamic> hayatiUyari = data['hayati_uyari'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Detayı"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSafe && hayatiUyari.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 25),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: AppTheme.dangerColor.withOpacity(0.5), blurRadius: 15, spreadRadius: 5)
                      ]
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.warning, color: Colors.white, size: 50),
                        const SizedBox(height: 10),
                        const Text("HAYATİ UYARI!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          "Bu ürün profilinizde bulunan şu alerjenleri içeriyor:\n\n${hayatiUyari.join(', ')}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                // Sağlık Puanı Kartı
                if (saglikPuani != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    child: Column(
                      children: [
                        const Text("Sağlık Puanı", style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text(
                          saglikPuani.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          saglikYorumu,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 25),

                // Alerjen Uyarıları
                if (alerjenler.isNotEmpty) ...[
                  const Text("Aktif Bileşenler & Alerjenler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                  const SizedBox(height: 10),
                  Wrap(
                    children: alerjenler.map((e) => AllergenBadge(allergen: e.toString())).toList(),
                  ),
                  const SizedBox(height: 25),
                ],

                // İçindekiler Tablosu
                if (icerikler.isNotEmpty) ...[
                  const Text("İçindekiler Analizi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: icerikler.length,
                      separatorBuilder: (c, i) => Divider(color: Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final item = icerikler[index];
                        
                        // Kategori ve Risk bilgisini al
                        String kategori = item['kategori'] ?? "-";
                        String risk = item['risk_seviyesi'] ?? "-";
                        
                        // Risk rengini belirle
                        Color riskColor = Colors.grey;
                        if (risk.toLowerCase().contains("düşük")) riskColor = AppTheme.successColor;
                        else if (risk.toLowerCase().contains("orta")) riskColor = Colors.orange;
                        else if (risk.toLowerCase().contains("yüksek")) riskColor = AppTheme.dangerColor;

                        return ListTile(
                          title: Text(item['bilesen'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                if (kategori != "-")
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(kategori, style: TextStyle(fontSize: 12, color: Colors.blue[800])),
                                  ),
                                if (kategori != "-") const SizedBox(width: 8),
                                if (risk != "-")
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: riskColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text("Risk: $risk", style: TextStyle(fontSize: 12, color: riskColor, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text("%${item['oran_yuzde']} (${item['miktar_g']}g)", style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                ],

                // Besin Değerleri
                if (besinler.isNotEmpty) ...[
                  const Text("Besin Değerleri (100g)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                    ),
                    child: Column(
                      children: besinler.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key.toString().capitalize(), style: const TextStyle(color: Colors.black54)),
                            Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
                
                const SizedBox(height: 30),
                Center(child: Text("Kaynak: $source", style: const TextStyle(color: Colors.grey, fontSize: 12))),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
                // RUTİNİME EKLE BUTONU (Alt kısma sabitli)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -5),
                    blurRadius: 10,
                  )
                ]
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!isSafe) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Bu ürün sizin için riskli, rutine eklenemez!"),
                        backgroundColor: AppTheme.dangerColor,
                        behavior: SnackBarBehavior.floating,
                      )
                    );
                    return;
                  }
                  
                  // Dialog Göster
                  _showRoutineTimeDialog(context, resultData, data, besinler);
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Rutinime Ekle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSafe ? AppTheme.successColor : AppTheme.dangerColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoutineTimeDialog(BuildContext context, Map<String, dynamic> resultData, Map data, Map besinler) {
    List<String> selectedTimes = [];
    final times = ["Sabah", "Öğle", "Akşam"];

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Hangi Öğüne Eklensin?", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: times.map((t) => CheckboxListTile(
                  title: Text(t),
                  activeColor: AppTheme.primaryColor,
                  value: selectedTimes.contains(t),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) selectedTimes.add(t);
                      else selectedTimes.remove(t);
                    });
                  },
                )).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("İptal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedTimes.isEmpty) return;
                    Navigator.pop(ctx);
                    
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      List<String> routineItems = prefs.getStringList('routine_items') ?? [];
                      
                      String productName = resultData['product_name'] ?? data['name'] ?? "Bilinmeyen Ürün";
                      String kalori = besinler['kalori'] != null ? "${besinler['kalori']} Kalori" : "Kalori bilgisi yok";

                      for (String time in selectedTimes) {
                        final newItem = {
                          "title": productName,
                          "desc": "$kalori - Güvenli Tüketim",
                          "done": false,
                          "time": time, 
                        };
                        routineItems.add(jsonEncode(newItem));
                      }
                      
                      await prefs.setStringList('routine_items', routineItems);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ürün başarıyla rutinize eklendi!"),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                          )
                        );
                      }
                    } catch (e) {
                      print("Hata: $e");
                    }
                  },
                  child: const Text("Ekle"),
                )
              ],
            );
          }
        );
      }
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return "";
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}
