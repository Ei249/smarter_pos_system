// cSpell:ignore Haidilao socso SOCSO KWSP PERKESO Sutera Utama Berhad Deepavali
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
      title: 'Haidilao Enterprise HR Cloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          primary: const Color(0xFFB71C1C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F4F8),
        useMaterial3: true,
      ),
      home: const RootAuthWrapper(),
    );
  }
}

// ==========================================
// 认证网关
// ==========================================
class RootAuthWrapper extends StatefulWidget {
  const RootAuthWrapper({super.key});

  @override
  State<RootAuthWrapper> createState() => _RootAuthWrapperState();
}

class _RootAuthWrapperState extends State<RootAuthWrapper> {
  Map<String, dynamic>? _currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return LoginScreen(onLoginSuccess: (u) => setState(() => _currentUser = u));
    }
    return MainNavigator(
      user: _currentUser!,
      onLogout: () => setState(() => _currentUser = null),
    );
  }
}

// ==========================================
// 登录页 (支持 L1 / L2 / L3 一键切换体验)
// ==========================================
class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController(text: 'staff');
  final _passController = TextEditingController(text: '1234');
  bool _isLoading = false;
  String _errorMsg = '';

  Future<void> _performLogin([String? quickUser]) async {
    if (quickUser != null) {
      _userController.text = quickUser;
      _passController.text = '1234';
    }
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userController.text,
          'password': _passController.text,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        widget.onLoginSuccess(data['user']);
      } else {
        setState(() => _errorMsg = 'Invalid credentials.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Server offline! Please restart python app.py');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1F2C), Color(0xFF3A1C1C), Color(0xFF8E1616)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.soup_kitchen, size: 44, color: Color(0xFFB71C1C)),
                    ),
                    const SizedBox(height: 16),
                    const Text('HAIDILAO HR CLOUD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF1A1F2C))),
                    const SizedBox(height: 4),
                    const Text('Enterprise Attendance, Leave, Claims & Payroll', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFB71C1C)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFB71C1C)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    if (_errorMsg.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_errorMsg, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoading ? null : () => _performLogin(),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SIGN IN TO PORTAL', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('1-CLICK ROLE SWITCH (DEMO ACCOUNTS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildRoleChip('L1 Staff', 'Ng Zhe Wei', 'staff', Colors.blue[800]!),
                        const SizedBox(width: 8),
                        _buildRoleChip('L2 Manager', 'Eugene Tang', 'manager', Colors.orange[800]!),
                        const SizedBox(width: 8),
                        _buildRoleChip('L3 HR Admin', 'See Lin', 'admin', Colors.purple[800]!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String level, String name, String username, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => _performLogin(username),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(level, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 10, color: Colors.black87), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 主框架：动态权限导航栏
// ==========================================
class MainNavigator extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  const MainNavigator({super.key, required this.user, required this.onLogout});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  int _refreshTick = 0;

  void _triggerGlobalRefresh() {
    setState(() => _refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    final int roleLevel = widget.user['role_level'] ?? 1;

    Widget activePage;
    switch (_currentIndex) {
      case 0:
        activePage = PunchCardScreen(
          user: widget.user,
          onLogout: widget.onLogout,
          onPunchSuccess: _triggerGlobalRefresh,
        );
        break;
      case 1:
        activePage = AttendanceHistoryScreen(
          key: ValueKey('hist_$_refreshTick'),
          user: widget.user,
        );
        break;
      case 2:
        activePage = LeaveAndClaimsScreen(
          key: ValueKey('leave_$_refreshTick'),
          user: widget.user,
        );
        break;
      case 3:
        activePage = PayslipScreen(
          key: ValueKey('pay_$_refreshTick'),
          user: widget.user,
        );
        break;
      case 4:
        activePage = RoleCommandCenterScreen(
          key: ValueKey('role_$_refreshTick'),
          user: widget.user,
          onLogout: widget.onLogout,
          onDataChanged: _triggerGlobalRefresh,
        );
        break;
      default:
        activePage = const SizedBox();
    }

    String fifthTabLabel = 'My Pass';
    IconData fifthTabIcon = Icons.badge_outlined;
    if (roleLevel == 2) {
      fifthTabLabel = 'Review (L2)';
      fifthTabIcon = Icons.fact_check_outlined;
    } else if (roleLevel >= 3) {
      fifthTabLabel = 'HR Admin (L3)';
      fifthTabIcon = Icons.admin_panel_settings_outlined;
    }

    return Scaffold(
      body: activePage,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, -3))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFB71C1C),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _refreshTick++;
            });
          },
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.fingerprint, size: 24), label: 'Punch Card'),
            const BottomNavigationBarItem(icon: Icon(Icons.swap_vert_circle_outlined, size: 24), label: 'IN/OUT Log'),
            const BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined, size: 24), label: 'Leave & Claim'),
            const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined, size: 24), label: 'Payslip'),
            BottomNavigationBarItem(icon: Icon(fifthTabIcon, size: 24), label: fifthTabLabel),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 页面 1：打卡主页 + 门店公告栏 + 当月 KPI 统计卡片
// ==========================================
class PunchCardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  final VoidCallback onPunchSuccess;

  const PunchCardScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onPunchSuccess,
  });

  @override
  State<PunchCardScreen> createState() => _PunchCardScreenState();
}

class _PunchCardScreenState extends State<PunchCardScreen> {
  bool _isClockedIn = false;
  bool _isLoading = true;
  String _feedbackMessage = "Syncing terminal status...";
  String _currentTimeString = "";
  String _currentDateString = "";
  Map<String, dynamic> _kpi = {"shifts": 0, "hours": 0.0, "est_ot": 420.0};
  Map<String, dynamic> _notice = {"title": "Loading...", "content": "", "author": ""};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _syncStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
      _currentTimeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      _currentDateString = "${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}";
    });
  }

  Future<void> _syncStatus() async {
    try {
      final statusRes = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id']}),
      );
      if (statusRes.statusCode == 200 && mounted) {
        final sData = jsonDecode(statusRes.body);
        setState(() {
          _isClockedIn = sData['is_clocked_in'];
          _kpi = sData['kpi'] ?? _kpi;
          _notice = sData['announcement'] ?? _notice;
          _feedbackMessage = _isClockedIn
              ? "On Shift since ${sData['clock_in_time']}"
              : "Off-Duty • Ready for Clock IN";
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePunchCard() async {
    setState(() => _isLoading = true);
    final endpoint = _isClockedIn ? '/api/clock-out' : '/api/clock-in';

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id']}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _syncStatus();
        widget.onPunchSuccess();
        if (mounted) {
          final isOut = data['type'] == 'OUT';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOut
                  ? 'CLOCKED OUT (${data['time']}) • Shift Duration: ${data['total_hours']} hrs'
                  : 'CLOCKED IN (${data['time']})'),
              backgroundColor: isOut ? Colors.orange[800] : Colors.green[700],
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getRoleBadgeColor(int level) {
    if (level >= 3) return Colors.amber[700]!;
    if (level == 2) return Colors.cyanAccent[700]!;
    return Colors.greenAccent[700]!;
  }

  @override
  Widget build(BuildContext context) {
    final int roleLevel = widget.user['role_level'] ?? 1;

    return Scaffold(
      body: Column(
        children: [
          // 顶部商业级身份识别栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 42, 22, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E222D), Color(0xFF7F1414), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Text(
                        widget.user['full_name'].toString().substring(0, 2).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.user['full_name'],
                                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: _getRoleBadgeColor(roleLevel), borderRadius: BorderRadius.circular(6)),
                                child: Text('LEVEL $roleLevel', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${widget.user['role_title']} • ${widget.user['branch']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onLogout,
                      tooltip: 'Switch Role / Logout',
                      icon: const Icon(Icons.switch_account_outlined, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 门店实时广播横幅 (Noticeboard)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_rounded, color: Colors.amberAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_notice['title']}: ${_notice['content']}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 当月实时考勤 KPI 统计三联卡
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                _buildKpiMiniCard('Completed Shifts', '${_kpi['shifts']} Shifts', Icons.verified_outlined, Colors.blue[700]!),
                const SizedBox(width: 10),
                _buildKpiMiniCard('Logged Hours', '${_kpi['hours']} hrs', Icons.timer_outlined, Colors.teal[700]!),
                const SizedBox(width: 10),
                _buildKpiMiniCard('Live OT Pay', 'RM ${_kpi['est_ot']}', Icons.payments_outlined, Colors.green[800]!),
              ],
            ),
          ),
          const Spacer(),
          // 实时电子时钟
          Text(_currentTimeString, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF1E222D))),
          Text(_currentDateString, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const Spacer(),
          // 双态打卡大圆盘
          GestureDetector(
            onTap: _isLoading ? null : _handlePunchCard,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isClockedIn
                      ? [const Color(0xFFE65100), const Color(0xFFFF9800)]
                      : [const Color(0xFF1B5E20), const Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isClockedIn ? Colors.orange : Colors.green).withValues(alpha: 0.38),
                    blurRadius: 26,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isClockedIn ? Icons.logout_rounded : Icons.login_rounded, size: 48, color: Colors.white),
                          const SizedBox(height: 6),
                          Text(
                            _isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isClockedIn ? 'Tap to Record Exit' : 'Tap to Record Entry',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const Spacer(),
          // 底部状态条
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: _isClockedIn ? Colors.orange : Colors.green),
                const SizedBox(width: 10),
                Expanded(child: Text(_feedbackMessage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                const Text('Sutera GPS OK', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMiniCard(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 页面 2：“一进一出”独立考勤流水页
// ==========================================
class AttendanceHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const AttendanceHistoryScreen({super.key, required this.user});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<dynamic> _events = [];
  bool _isLoading = true;
  bool _viewAllBranch = false;

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
        body: jsonEncode({
          'staff_id': widget.user['staff_id'],
          'view_all': _viewAllBranch,
        }),
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _events = jsonDecode(response.body)['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canViewAll = (widget.user['role_level'] ?? 1) >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IN / OUT Punch Stream', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E222D),
        foregroundColor: Colors.white,
        actions: [
          if (canViewAll)
            Row(
              children: [
                const Text('All Staff', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _viewAllBranch,
                  activeThumbColor: Colors.amber,
                  onChanged: (val) {
                    setState(() => _viewAllBranch = val);
                    fetchHistory();
                  },
                ),
              ],
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final ev = _events[index];
                final bool isIn = ev['type'] == 'IN';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: isIn ? Colors.green[600]! : Colors.orange[700]!, width: 5)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isIn ? Colors.green[50] : Colors.orange[50],
                        child: Icon(isIn ? Icons.login_rounded : Icons.logout_rounded, color: isIn ? Colors.green[700] : Colors.orange[800]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isIn ? Colors.green[700] : Colors.orange[800],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isIn ? 'CLOCK IN (进)' : 'CLOCK OUT (出)',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(ev['staff_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Time: ${ev['time']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('Gate: ${ev['location']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (!isIn)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(10)),
                          child: Text('${ev['hours']}h', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
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
// 页面 3：请假与费用报销双合一中心 (展示审批人姓名 + 拒绝/批准理由 + 自动扣减假期余额)
// ==========================================
class LeaveAndClaimsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const LeaveAndClaimsScreen({super.key, required this.user});
  @override
  State<LeaveAndClaimsScreen> createState() => _LeaveAndClaimsScreenState();
}

class _LeaveAndClaimsScreenState extends State<LeaveAndClaimsScreen> {
  int _subTab = 0; // 0: Leave, 1: Expense Claims
  String _selectedLeave = 'AL (Annual Leave)';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  List<dynamic> _leaveHistory = [];
  Map<String, dynamic> _quotas = {"al_left": 12, "al_used": 0, "mc_left": 14, "mc_used": 0, "hl_left": 60, "hl_used": 0};

  // 报销表单控制器
  String _claimCat = 'Transport / Late Night Grab';
  final _claimAmountCtrl = TextEditingController();
  final _claimDescCtrl = TextEditingController();
  List<dynamic> _claimHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    try {
      final lRes = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/leave-list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id'], 'view_all': false}),
      );
      final cRes = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/claim-list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id'], 'view_all': false}),
      );
      if (lRes.statusCode == 200 && cRes.statusCode == 200 && mounted) {
        final lData = jsonDecode(lRes.body);
        setState(() {
          _leaveHistory = lData['data'];
          _quotas = lData['quotas'] ?? _quotas;
          _claimHistory = jsonDecode(cRes.body)['data'];
        });
      }
    } catch (_) {}
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
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeave() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Start Date and End Date!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    await http.post(
      Uri.parse('http://127.0.0.1:5000/api/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staff_id': widget.user['staff_id'],
        'leave_type': _selectedLeave,
        'start_date': _formatDate(_startDate),
        'end_date': _formatDate(_endDate),
        'reason': _reasonController.text,
      }),
    );
    setState(() {
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
    });
    _fetchAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave Request Sent! Switch to L2 Manager to approve/reject with remarks.'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _submitClaim() async {
    if (_claimAmountCtrl.text.trim().isEmpty) return;
    await http.post(
      Uri.parse('http://127.0.0.1:5000/api/claim-submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staff_id': widget.user['staff_id'],
        'category': _claimCat,
        'amount': double.tryParse(_claimAmountCtrl.text) ?? 0.0,
        'description': _claimDescCtrl.text,
      }),
    );
    _claimAmountCtrl.clear();
    _claimDescCtrl.clear();
    _fetchAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense Claim Submitted! Once approved, it will be added to Oct Payslip.'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave & Expense Claims', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E222D),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部切换：请假 vs 费用报销
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _subTab == 0 ? const Color(0xFFB71C1C) : Colors.white,
                      foregroundColor: _subTab == 0 ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _subTab = 0),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Leave Application', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _subTab == 1 ? const Color(0xFFB71C1C) : Colors.white,
                      foregroundColor: _subTab == 1 ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _subTab = 1),
                    icon: const Icon(Icons.receipt_outlined, size: 18),
                    label: const Text('Expense Claims', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_subTab == 0) ...[
              // 动态计算的假期余额卡片
              Row(
                children: [
                  _buildQuotaCard('Annual (AL)', '${_quotas['al_left']} Left', 'Used: ${_quotas['al_used']}d', Colors.blue[700]!),
                  const SizedBox(width: 10),
                  _buildQuotaCard('Medical (MC)', '${_quotas['mc_left']} Left', 'Used: ${_quotas['mc_used']}d', Colors.orange[800]!),
                  const SizedBox(width: 10),
                  _buildQuotaCard('Hosp. (HL)', '${_quotas['hl_left']} Left', 'Used: ${_quotas['hl_used']}d', Colors.purple[700]!),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Apply for Leave', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLeave,
                      decoration: InputDecoration(labelText: 'Leave Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: ['AL (Annual Leave)', 'MC (Medical Leave)', 'HL (Hospitalization Leave)', 'UP (Unpaid Leave)']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedLeave = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(true),
                            child: InputDecorator(
                              decoration: InputDecoration(labelText: 'Start Date', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              child: Text(_formatDate(_startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(false),
                            child: InputDecorator(
                              decoration: InputDecoration(labelText: 'End Date', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              child: Text(_formatDate(_endDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      decoration: InputDecoration(labelText: 'Applicant Reason', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _submitLeave,
                        child: const Text('SUBMIT LEAVE REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Leave History & Reviewer Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._leaveHistory.map((item) => _buildReviewedCard(
                    title: item['type'],
                    subtitle: '${item['start']} ➔ ${item['end']} • Applicant Reason: ${item['reason']}',
                    status: item['status'],
                    reviewer: item['reviewer_name'],
                    remark: item['review_remark'],
                    time: item['reviewed_at'],
                  )),
            ] else ...[
              // 费用报销申请表单
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Submit Expense Reimbursement Claim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _claimCat,
                      decoration: InputDecoration(labelText: 'Claim Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: [
                        'Transport / Late Night Grab',
                        'Medical / Clinic Receipt',
                        'Branch Kitchen Supply Purchase',
                        'Staff Meal / Team Allowance'
                      ].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                      onChanged: (val) => setState(() => _claimCat = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _claimAmountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Claim Amount (RM)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _claimDescCtrl,
                      decoration: InputDecoration(labelText: 'Receipt No. / Details', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _submitClaim,
                        child: const Text('SUBMIT REIMBURSEMENT CLAIM', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('My Claim History (Auto-syncs to Payslip)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._claimHistory.map((c) => _buildReviewedCard(
                    title: '${c['category']} — RM ${c['amount'].toStringAsFixed(2)}',
                    subtitle: 'Date: ${c['date']} • Details: ${c['description']}',
                    status: c['status'],
                    reviewer: c['reviewer_name'],
                    remark: c['review_remark'],
                    time: '',
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // 带有审批人姓名与拒绝/批准理由展示框的通用卡片
  Widget _buildReviewedCard({
    required String title,
    required String subtitle,
    required String status,
    required String reviewer,
    required String remark,
    required String time,
  }) {
    final isApproved = status == 'Approved';
    final isRejected = status == 'Rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApproved ? Colors.green.withValues(alpha: 0.4) : (isRejected ? Colors.red.withValues(alpha: 0.4) : Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green[100] : (isRejected ? Colors.red[100] : Colors.orange[100]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isApproved ? Colors.green[900] : (isRejected ? Colors.red[900] : Colors.orange[900]),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          // 如果已经被经理或总监审批过，清晰显示是谁批的、什么理由！
          if (reviewer.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green[50] : (isRejected ? Colors.red[50] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isApproved ? Icons.verified_user : Icons.gavel_rounded,
                        size: 15,
                        color: isApproved ? Colors.green[800] : Colors.red[800],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${isApproved ? "Approved" : "Rejected"} by: $reviewer ${time.isNotEmpty ? "($time)" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isApproved ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (remark.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Decision Reason / Remark: "$remark"',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isApproved ? Colors.green[900] : Colors.red[900],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaCard(String title, String leftStr, String usedStr, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(leftStr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(usedStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 页面 4：16个月三级联动薪水单 (含报销入账展示)
// ==========================================
class PayslipScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const PayslipScreen({super.key, required this.user});
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
    fetchAllPayslips();
  }

  Future<void> fetchAllPayslips() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/payslips-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id']}),
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _allPayslips = jsonDecode(response.body)['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPayslipDetailSheet(String year, Map<String, dynamic> slip) {
    final double claims = (slip['claims_reimbursement'] ?? 0.0).toDouble();
    final grossPay = (slip['basic_salary'] + slip['ot_pay'] + slip['commission'] + slip['attendance_bonus'] + claims).toStringAsFixed(2);
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${slip['month']} $year Official Payslip', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${slip['staff_name']} • Date: ${slip['pay_date']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)),
                    child: Text(slip['status'], style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildRow('Basic Salary', 'RM ${slip['basic_salary'].toStringAsFixed(2)}'),
              _buildRow('Overtime & Shift Allowance', 'RM ${slip['ot_pay'].toStringAsFixed(2)}'),
              _buildRow('Table Commission (Haidilao)', 'RM ${slip['commission'].toStringAsFixed(2)}'),
              _buildRow('Bonus / Incentive', 'RM ${slip['attendance_bonus'].toStringAsFixed(2)}'),
              _buildRow('Approved Expense Claims', 'RM ${claims.toStringAsFixed(2)}'),
              _buildRow('Gross Earnings', 'RM $grossPay', isBold: true),
              const Divider(height: 22),
              _buildRow('EPF (KWSP 11%)', '- RM ${slip['epf'].toStringAsFixed(2)}', isRed: true),
              _buildRow('SOCSO (PERKESO)', '- RM ${slip['socso'].toStringAsFixed(2)}', isRed: true),
              _buildRow('EIS (SIP)', '- RM ${slip['eis'].toStringAsFixed(2)}', isRed: true),
              _buildRow('Total Deductions', '- RM $totalDeduction', isRed: true, isBold: true),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NET PAY (TAKE HOME)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    Text('RM ${slip['net_pay'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String amount, {bool isRed = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13.5)),
          Text(amount, style: TextStyle(color: isRed ? Colors.red[700] : Colors.black87, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: 13.5)),
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
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedYear = null))
            : null,
        title: Text(_selectedYear == null ? 'Payroll Archive (By Year)' : '$_selectedYear Monthly Statements', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E222D),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: fetchAllPayslips)],
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
                          child: const Icon(Icons.folder_copy_outlined, color: Color(0xFFB71C1C), size: 28),
                        ),
                        title: Text('Year $year Archive', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: Text('${monthsList.length} Monthly Payslips Available'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFB71C1C),
                          child: Text(slip['month_num'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('${slip['month']} $_selectedYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: Text('Credited: ${slip['pay_date']} • ${slip['status']}'),
                        trailing: Text('RM ${slip['net_pay'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2E7D32))),
                        onTap: () => _showPayslipDetailSheet(_selectedYear!, slip),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================================
// 页面 5：多角色权限控制中心 (支持实名写拒绝/批准理由弹窗、报销审批、发布公告与调薪)
// ==========================================
class RoleCommandCenterScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  final VoidCallback onDataChanged;

  const RoleCommandCenterScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onDataChanged,
  });

  @override
  State<RoleCommandCenterScreen> createState() => _RoleCommandCenterScreenState();
}

class _RoleCommandCenterScreenState extends State<RoleCommandCenterScreen> {
  List<dynamic> _allLeaves = [];
  List<dynamic> _allClaims = [];
  List<dynamic> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadRoleData();
  }

  Future<void> _loadRoleData() async {
    final int role = widget.user['role_level'] ?? 1;
    if (role >= 2) {
      final lRes = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/leave-list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id'], 'view_all': true}),
      );
      final cRes = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/claim-list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id'], 'view_all': true}),
      );
      if (lRes.statusCode == 200 && cRes.statusCode == 200 && mounted) {
        setState(() {
          _allLeaves = jsonDecode(lRes.body)['data'];
          _allClaims = jsonDecode(cRes.body)['data'];
        });
      }
    }
    if (role >= 3) {
      final uRes = await http.post(Uri.parse('http://127.0.0.1:5000/api/users'));
      if (uRes.statusCode == 200 && mounted) {
        setState(() => _allUsers = jsonDecode(uRes.body)['data']);
      }
    }
  }

  // 核心新功能：弹窗输入审批理由（拒绝时必填理由，自动绑定当前经理姓名与职位）
  void _openDecisionDialog({
    required bool isLeave,
    required int recordId,
    required String staffName,
    required String itemTitle,
    required String targetStatus,
  }) {
    final bool isReject = targetStatus == 'Rejected';
    final remarkCtrl = TextEditingController(
      text: isReject ? '' : 'Approved as per company policy.',
    );
    final reviewerIdentity = '${widget.user['full_name']} (${widget.user['role_title']})';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$targetStatus Request: $staffName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: $itemTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Reviewer: $reviewerIdentity', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 14),
            TextField(
              controller: remarkCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isReject ? 'Rejection Reason (Required *)' : 'Approval Note / Remark',
                hintText: isReject ? 'e.g. Weekend peak shift shortage / Missing MC receipt' : 'Optional note',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isReject ? Colors.red[700] : Colors.green[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (isReject && remarkCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason for rejection!'), backgroundColor: Colors.red),
                );
                return;
              }
              final url = isLeave ? 'http://127.0.0.1:5000/api/leave-approve' : 'http://127.0.0.1:5000/api/claim-approve';
              final idKey = isLeave ? 'leave_id' : 'claim_id';
              await http.post(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  idKey: recordId,
                  'status': targetStatus,
                  'reviewer_name': reviewerIdentity,
                  'review_remark': remarkCtrl.text.trim(),
                }),
              );
              if (context.mounted) Navigator.pop(context);
              _loadRoleData();
              widget.onDataChanged();
            },
            child: Text('Confirm $targetStatus'),
          ),
        ],
      ),
    );
  }

  void _showPostNoticeDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorIdentity = '${widget.user['full_name']} (${widget.user['role_title']})';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Branch Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Notice Title')),
            const SizedBox(height: 10),
            TextField(controller: contentCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Message Content')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            onPressed: () async {
              await http.post(
                Uri.parse('http://127.0.0.1:5000/api/announcement-post'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'title': titleCtrl.text,
                  'content': contentCtrl.text,
                  'author': authorIdentity,
                }),
              );
              if (context.mounted) Navigator.pop(context);
              widget.onDataChanged();
            },
            child: const Text('Publish Now'),
          ),
        ],
      ),
    );
  }

  void _showEditSalaryDialog(Map<String, dynamic> targetUser) {
    final basicCtrl = TextEditingController(text: targetUser['basic_salary'].toString());
    final bonusCtrl = TextEditingController(text: targetUser['custom_bonus'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Payroll: ${targetUser['full_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: basicCtrl, decoration: const InputDecoration(labelText: 'Basic Salary (RM)')),
            const SizedBox(height: 12),
            TextField(controller: bonusCtrl, decoration: const InputDecoration(labelText: 'Monthly Bonus (RM)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            onPressed: () async {
              await http.post(
                Uri.parse('http://127.0.0.1:5000/api/update-salary'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'staff_id': targetUser['staff_id'],
                  'basic_salary': basicCtrl.text,
                  'custom_bonus': bonusCtrl.text,
                  'role_level': targetUser['role_level'],
                  'role_title': targetUser['role_title'],
                }),
              );
              if (context.mounted) Navigator.pop(context);
              _loadRoleData();
              widget.onDataChanged();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int roleLevel = widget.user['role_level'] ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          roleLevel == 1 ? 'My Digital Staff Pass (L1)' : (roleLevel == 2 ? 'Manager Review Desk (L2)' : 'HR Director Console (L3)'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E222D),
        foregroundColor: Colors.white,
        actions: [
          if (roleLevel >= 2)
            IconButton(
              onPressed: _showPostNoticeDialog,
              tooltip: 'Post Branch Announcement',
              icon: const Icon(Icons.campaign_outlined, color: Colors.amberAccent),
            ),
          TextButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, color: Colors.amberAccent, size: 18),
            label: const Text('Switch Role', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 电子工牌卡片
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(radius: 26, backgroundColor: Color(0xFFB71C1C), child: Icon(Icons.verified_user, color: Colors.white)),
                    title: Text('${widget.user['full_name']} (Level $roleLevel)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('${widget.user['role_title']} • ${widget.user['branch']}'),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bank Account:', style: TextStyle(color: Colors.grey)),
                      Text(widget.user['bank_info'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Statutory EPF ID:', style: TextStyle(color: Colors.grey)),
                      Text(widget.user['epf_no'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // L2 经理 & L3 总监专属：实名请假审批 + 报销审批
            if (roleLevel >= 2) ...[
              const Text('1. LEAVE APPROVAL QUEUE (WITH REVIEWER REMARK)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C))),
              const SizedBox(height: 10),
              if (_allLeaves.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No leave requests found.')))
              else
                ..._allLeaves.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        title: Text('${item['staff_name']} • ${item['type']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${item['start']} ➔ ${item['end']} (${item['status']})\n'
                          '${item['reviewer_name'].toString().isNotEmpty ? "Reviewed by: ${item['reviewer_name']} — \"${item['review_remark']}\"" : "Staff Reason: ${item['reason']}"}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                              tooltip: 'Approve with Note',
                              onPressed: () => _openDecisionDialog(
                                isLeave: true,
                                recordId: item['id'],
                                staffName: item['staff_name'],
                                itemTitle: '${item['type']} (${item['start']} to ${item['end']})',
                                targetStatus: 'Approved',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                              tooltip: 'Reject with Reason',
                              onPressed: () => _openDecisionDialog(
                                isLeave: true,
                                recordId: item['id'],
                                staffName: item['staff_name'],
                                itemTitle: '${item['type']} (${item['start']} to ${item['end']})',
                                targetStatus: 'Rejected',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 18),
              const Text('2. EXPENSE CLAIM REIMBURSEMENT QUEUE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.teal)),
              const SizedBox(height: 10),
              if (_allClaims.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No expense claims submitted yet.')))
              else
                ..._allClaims.map((c) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        title: Text('${c['staff_name']} • RM ${c['amount'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${c['category']} (${c['status']})\n${c['reviewer_name'].toString().isNotEmpty ? "By ${c['reviewer_name']}: ${c['review_remark']}" : c['description']}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                              onPressed: () => _openDecisionDialog(
                                isLeave: false,
                                recordId: c['id'],
                                staffName: c['staff_name'],
                                itemTitle: '${c['category']} (RM ${c['amount']})',
                                targetStatus: 'Approved',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                              onPressed: () => _openDecisionDialog(
                                isLeave: false,
                                recordId: c['id'],
                                staffName: c['staff_name'],
                                itemTitle: '${c['category']} (RM ${c['amount']})',
                                targetStatus: 'Rejected',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 20),
            ],

            // L3 HR 总监专属：全员底薪与奖金调控台
            if (roleLevel >= 3) ...[
              const Text('3. MASTER PAYROLL & SALARY CONTROL (LEVEL 3 ONLY)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.purple)),
              const SizedBox(height: 10),
              ..._allUsers.map((u) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.purple[50], child: Text('L${u['role_level']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                      title: Text(u['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Basic: RM ${u['basic_salary']} | Bonus: RM ${u['custom_bonus']}'),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _showEditSalaryDialog(u),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Adjust Pay'),
                      ),
                    ),
                  )),
            ],

            // L1 普通员工排班表
            if (roleLevel == 1) ...[
              const Text('MY WEEKLY SHIFT ROSTER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.wb_sunny, color: Colors.orange),
                      title: Text('Mon - Wed (Morning Shift)', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('10:00 AM - 07:00 PM'),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.nights_stay, color: Colors.indigo),
                      title: Text('Thu - Sat (Closing Shift)', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('06:00 PM - 03:00 AM'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}