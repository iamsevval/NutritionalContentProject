import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  List<String> _favoriteItems = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedCategory = "Tümü";

  final List<String> _categories = ["Tümü", "Atıştırmalık", "İçecek", "Kahvaltılık", "Konserve", "Hazır Yemek"];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _fetchProducts();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteItems = prefs.getStringList('favorite_items') ?? [];
    });
  }

  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorite_items') ?? [];
    
    // Favori kaydederken name'i kullanıyoruz.
    String pName = product['name'] ?? "Bilinmeyen Ürün";
    String pImage = product['image'] ?? "";
    
    // JSON olarak objeyi kaydet
    final favObj = {"name": pName, "image": pImage};
    final jsonStr = jsonEncode(favObj);

    // Eğer zaten favoriyse çıkar, değilse ekle
    bool isExist = favs.any((element) {
      try {
        final decoded = jsonDecode(element);
        return decoded['name'] == pName;
      } catch(e) { return false; }
    });

    if (isExist) {
      favs.removeWhere((element) {
        try {
          return jsonDecode(element)['name'] == pName;
        } catch(e) { return false; }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilerden çıkarıldı.")));
    } else {
      favs.add(jsonStr);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilere eklendi!")));
    }

    await prefs.setStringList('favorite_items', favs);
    setState(() {
      _favoriteItems = favs;
    });
  }

  bool _isFavorite(String pName) {
    return _favoriteItems.any((element) {
      try {
        return jsonDecode(element)['name'] == pName;
      } catch(e) { return false; }
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      String url = "${ApiService.serverUrl}products/popular/";
      if (userId != null) {
        url += "?user_id=$userId";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allProducts = result['products'] ?? [];
            _filterLogic();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterLogic() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final name = (product['name'] as String).toLowerCase();
        final searchMatch = name.contains(_searchQuery.toLowerCase());
        
        final data = product['data'] ?? {};
        final category = data['kategori'] ?? "Diğer";
        
        final categoryMatch = _selectedCategory == "Tümü" || category == _selectedCategory;
        
        return searchMatch && categoryMatch;
      }).toList();
    });
  }

  void _openProduct(Map<String, dynamic> productData, String defaultName) {
    // ResultScreen'de "Bilinmeyen Ürün" hatasını çözmek için 'product_name' ekliyoruz
    productData['product_name'] = defaultName;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(resultData: {
          'data': productData,
          'product_name': defaultName, // Ek garanti
          'source': 'Önerilen Ürünler'
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Kataloğu"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.darkTextColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProducts,
              child: Column(
                children: [
                  // Arama ve Çipler
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Arama Çubuğu
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: TextField(
                            onChanged: (val) {
                              _searchQuery = val;
                              _filterLogic();
                            },
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Colors.grey),
                              hintText: "Ürün veya marka ara...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Çipler
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              bool isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : AppTheme.darkTextColor)),
                                  selected: isSelected,
                                  selectedColor: AppTheme.primaryColor,
                                  backgroundColor: Colors.white,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _selectedCategory = cat;
                                      _filterLogic();
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text("${_filteredProducts.length} ürün bulundu", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  
                  // GRID VIEW BÖLÜMÜ
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65, // Kartın uzunluğunu ayarlar
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final data = product['data'] ?? {};
                        final bool isSafe = data['is_safe'] ?? true;
                        final String pName = product['name'] ?? "İsimsiz";

                        return GestureDetector(
                          onTap: () => _openProduct(data, pName),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Resim ve İkonlar
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          product['image'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported))),
                                        ),
                                        // Favori Butonu
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => _toggleFavorite(product),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _isFavorite(pName) ? Icons.favorite : Icons.favorite_border,
                                                color: _isFavorite(pName) ? Colors.red : Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Dikkat Uyarısı
                                        if (!isSafe)
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.dangerColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Text("DİKKAT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Metinler
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          pName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            Icon(isSafe ? Icons.check_circle : Icons.warning, color: isSafe ? AppTheme.successColor : AppTheme.dangerColor, size: 14),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                isSafe ? "Güvenli" : "Riskli",
                                                style: TextStyle(color: isSafe ? AppTheme.successColor : AppTheme.dangerColor, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text("Puan: ${data['saglik_puani'] ?? '?'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
