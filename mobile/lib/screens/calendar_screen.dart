import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;
  
  // Örnek Seri Verileri
  int _currentStreak = 1;
  int _totalDays = 1;
  int _successRate = 100;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Rutin İlerlemesini Hesapla
      List<String> routineItems = prefs.getStringList('routine_items') ?? [];
      int totalTasks = routineItems.length;
      int doneTasks = 0;
      
      for(String str in routineItems) {
        try {
          final item = jsonDecode(str);
          if(item["done"] == true) doneTasks++;
        } catch(e) {}
      }
      
      // Bugün tamamlanan görev sayısını streak'e ekleme (Basit simülasyon)
      int currentStreak = prefs.getInt('current_streak') ?? 1;
      int lastDoneDate = prefs.getInt('last_done_date') ?? 0;
      int todayStr = DateTime.now().day;
      
      if (doneTasks > 0 && lastDoneDate != todayStr) {
        currentStreak++;
        prefs.setInt('current_streak', currentStreak);
        prefs.setInt('last_done_date', todayStr);
      }

      int successRate = totalTasks == 0 ? 0 : ((doneTasks / totalTasks) * 100).toInt();

      final userId = prefs.getInt('user_id');
      if (userId == null) {
        if(mounted) setState(() {
          _currentStreak = currentStreak;
          _successRate = successRate;
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(Uri.parse("${ApiService.serverUrl}history/$userId/"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['durum'] == 'basarili') {
          final history = data['history'] as List;
          Map<DateTime, List<dynamic>> newEvents = {};
          
          for (var item in history) {
            DateTime date = DateTime.parse(item['date']);
            DateTime dayKey = DateTime(date.year, date.month, date.day);
            if (newEvents[dayKey] == null) newEvents[dayKey] = [];
            newEvents[dayKey]!.add(item);
          }

          if (mounted) {
            setState(() {
              _events = newEvents;
              _currentStreak = currentStreak;
              _successRate = successRate;
              _isLoading = false;
            });
          }
        }
      } else {
        if(mounted) setState(() {
          _currentStreak = currentStreak;
          _successRate = successRate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    DateTime dayKey = DateTime(day.year, day.month, day.day);
    return _events[dayKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İlerleme"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seri Banner'ı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("🔥", style: TextStyle(fontSize: 32)),
                            const SizedBox(width: 10),
                            Text("$_currentStreak Günlük Seri!", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text("Peş peşe sağlıklı seçimler yapıyorsun!", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // İstatistik Kartları
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("🔥\n$_currentStreak", "Gün Seri", AppTheme.accentColor.withOpacity(0.1), AppTheme.accentColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard("✅\n$_totalDays", "Toplam Gün", AppTheme.successColor.withOpacity(0.1), AppTheme.successColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard("📈\n%$_successRate", "Bu Ay", AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  const Text("Rutin Takvimi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkTextColor)),
                  const SizedBox(height: 10),
                  
                  // Takvim
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      eventLoader: _getEventsForDay,
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.5), shape: BoxShape.circle),
                        selectedDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                        markerDecoration: const BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle),
                      ),
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Günün Geçmişi
                  if (_getEventsForDay(_selectedDay!).isNotEmpty) ...[
                    const Text("Günün Geçmişi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ..._getEventsForDay(_selectedDay!).map((event) {
                      bool isSafe = event['is_safe'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSafe ? AppTheme.successColor.withOpacity(0.2) : AppTheme.dangerColor.withOpacity(0.2),
                            child: Icon(isSafe ? Icons.check : Icons.warning, color: isSafe ? AppTheme.successColor : AppTheme.dangerColor),
                          ),
                          title: Text(event['product_name'] ?? 'Bilinmeyen Ürün', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isSafe ? "Sizin için güvenli" : "Alerjen tespit edildi!", style: TextStyle(color: isSafe ? AppTheme.successColor : AppTheme.dangerColor)),
                        ),
                      );
                    }).toList()
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text("Bu tarihte tarama yapılmamış.", style: TextStyle(color: Colors.grey))),
                    )
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
