import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const HRApp());
}

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haidilao HR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
    );
  }
}

// ==========================================
// 底部导航栏主控页面
// ==========================================
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  // 这是我们等下要放的 4 个页面
  final List<Widget> _pages = [
    const PunchCardScreen(),
    const AttendanceHistoryScreen(),
    const LeaveScreen(),
    const PayslipScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Clock In'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Leave'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payslip'),
        ],
      ),
    );
  }
}

// ==========================================
// 页面 1：打卡页 (保留你刚才写的联网功能)
// ==========================================
class PunchCardScreen extends StatefulWidget {
  const PunchCardScreen({super.key});

  @override
  State<PunchCardScreen> createState() => _PunchCardScreenState();
}

class _PunchCardScreenState extends State<PunchCardScreen> {
  String _statusMessage = "Welcome back, Zhe Wei!";
  bool _isLoading = false;

  Future<void> _clockIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Syncing with database...";
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/clock-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': 1}), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _statusMessage = "Success! Time: ${data['time']}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Network error. Is Python running?";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Punch Card'), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, size: 100, color: Colors.red),
            const SizedBox(height: 30),
            Text(_statusMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _isLoading 
                ? const CircularProgressIndicator(color: Colors.red)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
                    onPressed: _clockIn,
                    child: const Text('CLOCK IN / OUT', style: TextStyle(fontSize: 20)),
                  ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 页面 2：历史记录页 (UI 占位)
// ==========================================
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History'), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      body: const Center(child: Text('Next Week: Fetch SQLite data here.')),
    );
  }
}

// ==========================================
// 页面 3：请假申请页 (UI 占位)
// ==========================================
class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Application (MC/AL/HL)'), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      body: const Center(child: Text('Next Week: Build Leave Form here.')),
    );
  }
}

// ==========================================
// 页面 4：薪水单页 (UI 占位)
// ==========================================
class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Payslip'), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      body: const Center(child: Text('Next Week: Calculate Salary & Commission.')),
    );
  }
}