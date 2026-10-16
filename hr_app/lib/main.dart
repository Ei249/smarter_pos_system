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
// 页面 1：打卡页 (完美闭环版：包含上下班切换)
// ==========================================
class PunchCardScreen extends StatefulWidget {
  const PunchCardScreen({super.key});

  @override
  State<PunchCardScreen> createState() => _PunchCardScreenState();
}

class _PunchCardScreenState extends State<PunchCardScreen> {
  String _statusMessage = "Welcome back, Zhe Wei! Ready for work?";
  bool _isLoading = false;
  bool _isClockedIn = false; // 新增：记录当前打卡状态

  // 智能打卡函数：自动判断是请求 In 还是 Out
  Future<void> _handlePunchCard() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Syncing with database...";
    });

    try {
      // 如果还没上班，就打上班卡；如果已经上班，就打下班卡
      String endpoint = _isClockedIn ? '/api/clock-out' : '/api/clock-in';
      
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': 1}), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (_isClockedIn) {
            // 下班成功，显示下班时间和计算出的总工时
            _statusMessage = "Clocked OUT successfully!\nTime: ${data['time']}\nTotal Hours: ${data['total_hours']} hr";
            _isClockedIn = false; // 状态切回未上班
          } else {
            // 上班成功，显示上班时间
            _statusMessage = "Clocked IN successfully!\nTime: ${data['time']}";
            _isClockedIn = true; // 状态切换为已上班
          }
        });
      } else {
        setState(() {
          _statusMessage = "Error: Please check if you have an active session.";
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
            // 图标颜色也会跟着状态变
            Icon(Icons.touch_app, size: 100, color: _isClockedIn ? Colors.green : Colors.red),
            const SizedBox(height: 30),
            Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5)),
            const SizedBox(height: 50),
            _isLoading 
                ? const CircularProgressIndicator(color: Colors.red)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // 上班状态按钮变红，下班状态按钮变绿
                      backgroundColor: _isClockedIn ? Colors.grey[700] : Colors.red, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)
                    ),
                    onPressed: _handlePunchCard,
                    // 按钮文字自动切换
                    child: Text(_isClockedIn ? 'CLOCK OUT' : 'CLOCK IN', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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