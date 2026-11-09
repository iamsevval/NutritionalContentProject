import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'quiz_screen.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.dangerColor));
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError("Lütfen tüm alanları doldurun.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint = isLogin ? "login/" : "register/";
      final response = await http.post(
        Uri.parse("${ApiService.serverUrl}$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['durum'] == 'basarili') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', result['user_id']);
        
        if (!mounted) return;

        if (isLogin) {
          // Giriş yaptıysa ana sayfaya git
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
        } else {
          // Yeni kayıt olduysa alerji anketine git
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
        }
      } else {
        _showError(result['mesaj'] ?? "Hata oluştu.");
      }
    } catch (e) {
      _showError("Bağlantı hatası: $e");
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.health_and_safety, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 30),
              Text(
                isLogin ? "Hoş Geldiniz" : "Kayıt Ol",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Kullanıcı Adı", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 25),
              _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(isLogin ? "Giriş Yap" : "Kayıt Ol", style: const TextStyle(fontSize: 18)),
                    ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Hesabınız yok mu? Kayıt Olun" : "Zaten hesabınız var mı? Giriş Yapın"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
