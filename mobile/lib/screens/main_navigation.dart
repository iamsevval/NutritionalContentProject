import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'result_screen.dart';
import 'routine_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<Widget> _pages = [
    const HomeScreen(),
    const RoutineScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.dangerColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _processImage(ImageSource source) async {
    if (_isLoading) return;
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.uploadImage(File(image.path));
      if (!mounted) return;
      
      if (result['durum'] == 'basarili') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResultScreen(resultData: result['veri'])),
        );
      } else {
        _showError(result['mesaj'] ?? "Bilinmeyen bir hata oluştu.");
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scanBarcode() async {
    var res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SimpleBarcodeScannerPage(),
        ));

    if (res is String && res != '-1') {
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.sendBarcode(res);
        if (!mounted) return;

        if (result['durum'] == 'basarili') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ResultScreen(resultData: result['veri'])),
          );
        } else {
          _showError(result['mesaj'] ?? "Bilinmeyen bir hata oluştu.");
        }
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showScannerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ürün Tara", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text("Ambalaj Fotoğrafı Çek"),
              onTap: () {
                Navigator.pop(context);
                _processImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
              title: const Text("Barkod Okut"),
              onTap: () {
                Navigator.pop(context);
                _scanBarcode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text("Galeriden Seç"),
              onTap: () {
                Navigator.pop(context);
                _processImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold gövdesi için sayfayı seç
    int pageIndex = _currentIndex;
    if (_currentIndex > 2) {
      pageIndex = _currentIndex - 1;
    }

    return Stack(
      children: [
        Scaffold(
          body: _pages[pageIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              if (index == 2) {
                // Ürün Tara action
                _showScannerOptions();
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
              BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Rutin"),
              BottomNavigationBarItem(icon: Icon(Icons.document_scanner), label: "Ürün Tara"),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "İlerleme"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          ),
      ],
    );
  }
}
