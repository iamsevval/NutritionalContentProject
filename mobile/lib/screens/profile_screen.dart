import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'quiz_screen.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = "Kullanıcı";
  List<String> _allergies = [];
  List<String> _diseases = [];
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favsStr = prefs.getStringList('favorite_items') ?? [];
    setState(() {
      _favorites = favsStr.map((e) {
        try {
          return jsonDecode(e) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{};
        }
      }).where((e) => e.isNotEmpty).toList();
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username') ?? "Kullanıcı";
      
      setState(() {
        _username = username;
      });

      if (userId != null) {
        final response = await http.get(Uri.parse("${ApiService.serverUrl}profile/$userId/"));
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              final String allergyString = result['allergies'] ?? "";
              final String diseaseString = result['diseases'] ?? "";
              _allergies = allergyString.split(',').where((e) => e.trim().isNotEmpty).toList();
              _diseases = diseaseString.split(',').where((e) => e.trim().isNotEmpty).toList();
            });
          }
        }
      }
    } catch (e) {
      // Hata sessizce geçilebilir
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
  
  void _deleteAccount() async {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text("Hesabımı Sil"),
            content: const Text("Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz?"),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                    onPressed: () async {
                        Navigator.pop(ctx);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (!mounted) return;
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text("Sil")
                )
            ],
        )
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı Kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            _username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _username,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "$_username@besin.com",
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // FAVORİLERİM BUTONU
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: const Text("Favori Ürünlerim", style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())).then((_) {
                            // Geri dönünce listeyi güncelle
                            _loadFavorites();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Özellikler ve Bilgiler
                  const Text("Hesap Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                          title: const Text("Bilgilerimi Görüntüle", style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Hesap Bilgileri", style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Kullanıcı Adı:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      Text(_username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      Text("E-Posta:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      Text("$_username@besin.com", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      Text("Kayıtlı Alerji/Diyet Sayısı:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      Text("${_allergies.length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      Text("Kayıtlı Rahatsızlık Sayısı:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      Text("${_diseases.length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kapat"))
                                  ],
                                )
                              );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.monitor_weight_outlined, color: AppTheme.primaryColor),
                          title: const Text("Alerjilerim & Diyetim", style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text("${_allergies.length} Seçili", style: const TextStyle(color: Colors.grey)),
                        ),
                        if (_allergies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _allergies.map((a) => Chip(
                                    label: Text(a),
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  )).toList(),
                                ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            child: Align(alignment: Alignment.centerLeft, child: Text("Henüz bir alerji veya diyet seçmediniz.", style: TextStyle(color: Colors.grey))),
                          ),
                          
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.medical_services_outlined, color: AppTheme.dangerColor),
                          title: const Text("Rahatsızlıklarım (Klinik Tolerans)", style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text("${_diseases.length} Seçili", style: const TextStyle(color: Colors.grey)),
                        ),
                        if (_diseases.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _diseases.map((d) => Chip(
                                    label: Text(d),
                                    backgroundColor: AppTheme.dangerColor.withOpacity(0.1),
                                    labelStyle: const TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold),
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  )).toList(),
                                ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            child: Align(alignment: Alignment.centerLeft, child: Text("Herhangi bir kronik rahatsızlığınız bulunmuyor.", style: TextStyle(color: Colors.grey))),
                          ),
                        
                        // TESTİ TEKRAR ÇÖZ BUTONU
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
                              },
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text("Sağlık Profilimi Güncelle (Testi Tekrar Çöz)"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Alt Butonlar
                  Row(
                      children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout, color: AppTheme.darkTextColor),
                                  label: const Text("Çıkış", style: TextStyle(color: AppTheme.darkTextColor, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                  ),
                              )
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: _deleteAccount,
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                                  label: const Text("Hesabı Sil", style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.dangerColor),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                  ),
                              )
                          ),
                      ],
                  )
                ],
              ),
            ),
    );
  }
}
