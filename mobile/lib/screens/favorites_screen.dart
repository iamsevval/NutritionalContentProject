import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String pName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorite_items') ?? [];
    
    favs.removeWhere((element) {
      try {
        return jsonDecode(element)['name'] == pName;
      } catch(e) { return false; }
    });
    
    await prefs.setStringList('favorite_items', favs);
    setState(() {
      _favorites.removeWhere((e) => e['name'] == pName);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilerden çıkarıldı.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorilerim"),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text("Henüz favorilere ürün eklemediniz.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final fav = _favorites[index];
                  final String name = fav['name'] ?? "Bilinmeyen Ürün";
                  final String image = fav['image'] ?? "";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          image, 
                          width: 60, 
                          height: 60, 
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 60, 
                            height: 60, 
                            color: Colors.grey[200], 
                            child: const Icon(Icons.image_not_supported, color: Colors.grey)
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _removeFavorite(name),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
