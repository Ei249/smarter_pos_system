// cSpell:ignore Haidilao socso SOCSO KWSP PERKESO
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const HRApp());
}

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haidilao Staff Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          primary: const Color(0xFFD32F2F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
    );
  }
}

// ==========================================
// 底部导航主框架 (使用 IndexedStack 保持页面状态)
// ==========================================
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final GlobalKey<_AttendanceHistoryScreenState> _historyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PunchCardScreen(onPunchSuccess: () => _historyKey.currentState?.fetchHistory()),
      AttendanceHistoryScreen(key: _historyKey),
      const LeaveScreen(),
      const PayslipScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFD32F2F),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) {
              _historyKey.currentState?.fetchHistory();
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.fingerprint, size: 26), label: 'Clock In/Out'),
            BottomNavigationBarItem(icon: Icon(Icons.history_edu, size: 26), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month, size: 26), label: 'Leave'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet, size: 26), label: 'Payslip'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 页面 1：智能打卡页 (实时时钟 + 数据库状态同步)
// ==========================================
class PunchCardScreen extends StatefulWidget {
  final VoidCallback onPunchSuccess;
  const PunchCardScreen({super.key, required this.onPunchSuccess});

  @override
  State<PunchCardScreen> createState() => _PunchCardScreenState();
}

class _PunchCardScreenState extends State<PunchCardScreen> {
  bool _isClockedIn = false;
  bool _isLoading = true;
  String _activeClockInTime = "";
  String _feedbackMessage = "Ready to start your shift?";
  String _currentTimeString = "";
  String _currentDateString = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _syncStatusFromServer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentTimeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      _currentDateString = "${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}";
    });
  }

  Future<void> _syncStatusFromServer() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': 1}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isClockedIn = data['is_clocked_in'];
          if (_isClockedIn) {
            _activeClockInTime = data['clock_in_time'];
            _feedbackMessage = "On Shift since $_activeClockInTime";
          } else {
            _feedbackMessage = "You are currently off-duty.";
          }
        });
      }
    } catch (e) {
      setState(() => _feedbackMessage = "Cannot connect to server. Is Python running?");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePunchCard() async {
    setState(() => _isLoading = true);
    final endpoint = _isClockedIn ? '/api/clock-out' : '/api/clock-in';

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': 1}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          if (_isClockedIn) {
            _isClockedIn = false;
            _activeClockInTime = "";
            _feedbackMessage = "Shift Completed! Total Hours: ${data['total_hours']} hrs";
          } else {
            _isClockedIn = true;
            _activeClockInTime = data['time'];
            _feedbackMessage = "Clocked IN at $_activeClockInTime";
          }
        });
        widget.onPunchSuccess();
      } else {
        await _syncStatusFromServer();
      }
    } catch (e) {
      setState(() => _feedbackMessage = "Network Error: Please check Python server.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Text('ZW', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ng Zhe Wei', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Staff ID: #HDL-001 • Service Crew', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isClockedIn ? Colors.greenAccent[700] : Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: _isClockedIn ? Colors.white : Colors.grey[300]),
                          const SizedBox(width: 6),
                          Text(_isClockedIn ? 'ON DUTY' : 'OFF DUTY', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(_currentTimeString, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF2C3E50))),
          const SizedBox(height: 4),
          Text(_currentDateString, style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: _isLoading ? null : _handlePunchCard,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isClockedIn
                      ? [const Color(0xFF2E7D32), const Color(0xFF66BB6A)]
                      : [const Color(0xFFC62828), const Color(0xFFEF5350)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isClockedIn ? Colors.green : Colors.red).withValues(alpha: 0.35),
                    blurRadius: 25,
                    spreadRadius: 6,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isClockedIn ? Icons.logout_rounded : Icons.touch_app_rounded, size: 58, color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            _isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isClockedIn ? 'Tap to end shift' : 'Tap to start shift',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Icon(_isClockedIn ? Icons.timer : Icons.info_outline, color: _isClockedIn ? Colors.green[700] : const Color(0xFFD32F2F)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_feedbackMessage, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.sync, size: 20, color: Colors.grey),
                  tooltip: 'Sync Status',
                  onPressed: _syncStatusFromServer,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 页面 2：考勤历史记录页 (商业级卡片列表)
// ==========================================
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<dynamic> _historyRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': 1}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _historyRecords = jsonDecode(response.body)['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Log', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyRecords.isEmpty
              ? const Center(child: Text('No attendance records yet.', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyRecords.length,
                  itemBuilder: (context, index) {
                    final r = _historyRecords[index];
                    final isWorking = r['out'] == "Active Shift";
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isWorking ? Colors.green.withValues(alpha: 0.5) : Colors.transparent, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isWorking ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(isWorking ? Icons.timelapse : Icons.fact_check_outlined, color: isWorking ? Colors.green[700] : const Color(0xFFD32F2F)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Clock In:  ${r['in']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 6),
                                Text(
                                  'Clock Out: ${r['out']}',
                                  style: TextStyle(color: isWorking ? Colors.green[700] : Colors.grey[700], fontWeight: isWorking ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isWorking ? Colors.green[100] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isWorking ? 'ON DUTY' : '${r['hours']} hrs',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isWorking ? Colors.green[800] : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================================
// 页面 3：请假申请页 (原生日历选择器 + 申请记录)
// ==========================================
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  String _selectedLeave = 'MC (Medical Leave)';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  List<dynamic> _leaveHistory = [];

  final List<String> _leaveTypes = [
    'MC (Medical Leave)',
    'AL (Annual Leave)',
    'HL (Hospitalization Leave)',
    'UP (Unpaid Leave)',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeaveHistory();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select Date';
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFD32F2F)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeave() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Start Date and End Date from the calendar!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staff_id': 1,
        'leave_type': _selectedLeave,
        'start_date': _formatDate(_startDate),
        'end_date': _formatDate(_endDate),
        'reason': _reasonController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
      });
      _fetchLeaveHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave application submitted successfully!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _fetchLeaveHistory() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/leave-list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': 1}),
      );
      if (response.statusCode == 200) {
        setState(() => _leaveHistory = jsonDecode(response.body)['data']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildQuotaCard('Annual (AL)', '12 Days', Colors.blue),
                const SizedBox(width: 10),
                _buildQuotaCard('Medical (MC)', '14 Days', Colors.orange),
                const SizedBox(width: 10),
                _buildQuotaCard('Hosp. (HL)', '60 Days', Colors.purple),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Apply for Leave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLeave,
                    decoration: InputDecoration(
                      labelText: 'Leave Category',
                      prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFFD32F2F)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _leaveTypes.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) => setState(() => _selectedLeave = val!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(true),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              prefixIcon: const Icon(Icons.calendar_today, size: 20, color: Color(0xFFD32F2F)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _formatDate(_startDate),
                              style: TextStyle(color: _startDate == null ? Colors.grey : Colors.black87, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(false),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date',
                              prefixIcon: const Icon(Icons.event, size: 20, color: Color(0xFFD32F2F)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _formatDate(_endDate),
                              style: TextStyle(color: _endDate == null ? Colors.grey : Colors.black87, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason / Remarks (Optional)',
                      prefixIcon: const Icon(Icons.notes, color: Color(0xFFD32F2F)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitLeave,
                      icon: const Icon(Icons.send),
                      label: const Text('SUBMIT REQUEST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Applications', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _leaveHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No leave applications submitted yet.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _leaveHistory.length,
                    itemBuilder: (context, index) {
                      final item = _leaveHistory[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFEBEE),
                            child: Icon(Icons.event_note, color: Color(0xFFD32F2F)),
                          ),
                          title: Text(item['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item['start']}  ➔  ${item['end']}\nReason: ${item['reason']}'),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                            child: Text(item['status'], style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaCard(String title, String days, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Text(days, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 页面 4：三级联动薪水单页 (选年份 ➔ 选月份 ➔ 看详情)
// ==========================================
class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});
  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  Map<String, dynamic> _allPayslips = {};
  String? _selectedYear;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllPayslips();
  }

  Future<void> _fetchAllPayslips() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/payslips-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': 1}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _allPayslips = jsonDecode(response.body)['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showPayslipDetailSheet(String year, Map<String, dynamic> slip) {
    final grossPay = (slip['basic_salary'] + slip['ot_pay'] + slip['commission'] + slip['attendance_bonus']).toStringAsFixed(2);
    final totalDeduction = (slip['epf'] + slip['socso'] + slip['eis']).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${slip['month']} $year Payslip', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Pay Date: ${slip['pay_date']} • Ng Zhe Wei', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)),
                    child: Text(slip['status'], style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Align(alignment: Alignment.centerLeft, child: Text('EARNINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
              const SizedBox(height: 8),
              _buildRow('Basic Salary', 'RM ${slip['basic_salary'].toStringAsFixed(2)}'),
              _buildRow('Overtime (OT)', 'RM ${slip['ot_pay'].toStringAsFixed(2)}'),
              _buildRow('Table Commission (Haidilao)', 'RM ${slip['commission'].toStringAsFixed(2)}'),
              _buildRow('Full Attendance Bonus', 'RM ${slip['attendance_bonus'].toStringAsFixed(2)}'),
              _buildRow('Gross Earnings', 'RM $grossPay', isBold: true),
              const Divider(height: 28),
              const Align(alignment: Alignment.centerLeft, child: Text('STATUTORY DEDUCTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
              const SizedBox(height: 8),
              _buildRow('EPF (KWSP 11%)', '- RM ${slip['epf'].toStringAsFixed(2)}', isRed: true),
              _buildRow('SOCSO (PERKESO)', '- RM ${slip['socso'].toStringAsFixed(2)}', isRed: true),
              _buildRow('EIS (SIP)', '- RM ${slip['eis'].toStringAsFixed(2)}', isRed: true),
              _buildRow('Total Deductions', '- RM $totalDeduction', isRed: true, isBold: true),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NET PAY (Take Home)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    Text('RM ${slip['net_pay'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String amount, {bool isRed = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
          Text(amount, style: TextStyle(color: isRed ? Colors.red[700] : Colors.black87, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = _allPayslips.keys.toList();

    return Scaffold(
      appBar: AppBar(
        leading: _selectedYear != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedYear = null),
              )
            : null,
        title: Text(
          _selectedYear == null ? 'Select Payslip Year' : '$_selectedYear Monthly Payslips',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedYear == null
              ? ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    final monthsList = _allPayslips[year] as List<dynamic>;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.folder_copy_outlined, color: Color(0xFFD32F2F), size: 28),
                        ),
                        title: Text('Year $year', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                        subtitle: Text('${monthsList.length} Monthly Statements Available', style: const TextStyle(color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                        onTap: () => setState(() => _selectedYear = year),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: (_allPayslips[_selectedYear] as List).length,
                  itemBuilder: (context, index) {
                    final slip = (_allPayslips[_selectedYear] as List)[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFD32F2F),
                          child: Text(slip['month_num'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('${slip['month']} $_selectedYear', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        subtitle: Text('Credited on ${slip['pay_date']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('RM ${slip['net_pay'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32))),
                            const Text('Tap to view', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        onTap: () => _showPayslipDetailSheet(_selectedYear!, slip),
                      ),
                    );
                  },
                ),
    );
  }
}