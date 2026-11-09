import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<String> commonAllergies = [
    "Gluten", "Süt", "Yer Fıstığı", "Yumurta", "Soya", "Deniz Ürünleri", "Ağaç Yemişleri"
  ];
  final Set<String> _selectedAllergies = {};
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      final response = await http.post(
        Uri.parse("${ApiService.serverUrl}profile/$userId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"allergies": _selectedAllergies.join(",")}),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text("Sağlık Profiliniz", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
              const SizedBox(height: 10),
              const Text("Size özel uyarılar verebilmemiz için bilinen alerjilerinizi seçin.", style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 30),
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
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("Devam Et", style: TextStyle(fontSize: 18)),
                    ),
                  )
            ],
          ),
        ),
      ),
    );
  }
}
