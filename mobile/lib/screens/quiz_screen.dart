import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'main_navigation.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentStep = 0;
  bool _hasAllergies = false;
  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedDiseases = {};
  String _customAllergies = "";
  String _dietType = "Yok";
  bool _isLoading = false;

  final List<String> commonAllergies = [
    "Gluten", "Süt", "Yer Fıstığı", "Yumurta", "Soya", "Deniz Ürünleri", "Ağaç Yemişleri"
  ];

  final List<String> dietTypes = [
    "Yok", "Vegan", "Vejetaryen", "Ketojenik"
  ];

  final List<String> commonDiseases = [
    "Diyabet", "Tansiyon", "Çölyak", "İrritabl Bağırsak Sendromu (IBS)"
  ];

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      // Diyet türünü alerjilere tag olarak ekliyoruz (Backend uyumluluğu için)
      List<String> allTags = _selectedAllergies.toList();
      if (_dietType != "Yok") {
        allTags.add(_dietType);
      }
      
      // Özel alerjileri ekle
      if (_customAllergies.trim().isNotEmpty) {
        final customList = _customAllergies.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        allTags.addAll(customList);
      }

      final response = await http.post(
        Uri.parse("${ApiService.serverUrl}profile/$userId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "allergies": allTags.join(","),
          "diseases": _selectedDiseases.join(",")
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && !_hasAllergies) {
      // Alerjisi yoksa direkt diyet sorusuna atla
      setState(() => _currentStep = 2);
    } else if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: Colors.grey[200],
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 40),
              
              if (_currentStep == 0) ...[
                const Text("Sizi Daha Yakından Tanıyalım", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                const SizedBox(height: 20),
                const Text("Herhangi bir gıdaya karşı alerjiniz veya hassasiyetiniz var mı?", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_hasAllergies ? AppTheme.primaryColor : Colors.grey[200],
                          foregroundColor: !_hasAllergies ? Colors.white : Colors.black,
                        ),
                        onPressed: () => setState(() => _hasAllergies = false),
                        child: const Text("Hayır"),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasAllergies ? AppTheme.primaryColor : Colors.grey[200],
                          foregroundColor: _hasAllergies ? Colors.white : Colors.black,
                        ),
                        onPressed: () => setState(() => _hasAllergies = true),
                        child: const Text("Evet, var"),
                      ),
                    ),
                  ],
                ),
              ],

              if (_currentStep == 1) ...[
                const Text("Hangi besinlere alerjiniz var?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                const SizedBox(height: 20),
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: commonAllergies.map((allergy) {
                      final isSelected = _selectedAllergies.contains(allergy);
                      return FilterChip(
                        label: Text(allergy),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                        checkmarkColor: AppTheme.primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) _selectedAllergies.add(allergy);
                            else _selectedAllergies.remove(allergy);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 15),
                const Text("Listede olmayan başka bir hassasiyetiniz var mı?", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (val) {
                    _customAllergies = val;
                  },
                  decoration: InputDecoration(
                    hintText: "Örn: Çilek, Şeker, Palm Yağı, MSG",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    )
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (_currentStep == 2) ...[
                const Text("Özel bir diyet uyguluyor musunuz?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: dietTypes.length,
                    itemBuilder: (context, index) {
                      final diet = dietTypes[index];
                      return RadioListTile<String>(
                        title: Text(diet),
                        value: diet,
                        groupValue: _dietType,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() => _dietType = value!);
                        },
                      );
                    },
                  ),
                ),
              ],

              if (_currentStep == 3) ...[
                const Text("Kronik bir rahatsızlığınız var mı?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                const SizedBox(height: 10),
                const Text("Sizin için en doğru tıbbi analizleri yapabilmemiz için lütfen işaretleyin.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 20),
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: commonDiseases.map((disease) {
                      final isSelected = _selectedDiseases.contains(disease);
                      return FilterChip(
                        label: Text(disease),
                        selected: isSelected,
                        selectedColor: AppTheme.dangerColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.dangerColor,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) _selectedDiseases.add(disease);
                            else _selectedDiseases.remove(disease);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],

              const Spacer(),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      child: Text(_currentStep == 3 ? "Profili Tamamla" : "Sonraki", style: const TextStyle(fontSize: 18)),
                    ),
                  )
            ],
          ),
        ),
      ),
    );
  }
}
