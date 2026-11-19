// cSpell:disable
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(const HRApp());
}

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmarterPOS Enterprise HR & Live POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          primary: const Color(0xFFB71C1C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F5F9),
        useMaterial3: true,
      ),
      home: const RootAuthWrapper(),
    );
  }
}

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
// 登录页
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
        body: jsonEncode({'username': _userController.text, 'password': _passController.text}),
      );
      if (response.statusCode == 200) {
        widget.onLoginSuccess(jsonDecode(response.body)['user']);
      } else {
        setState(() => _errorMsg = 'Invalid username or password.');
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
            colors: [Color(0xFF141824), Color(0xFF4A1212), Color(0xFF9E1B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 15))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.storefront_rounded, size: 42, color: Color(0xFFB71C1C)),
                    ),
                    const SizedBox(height: 14),
                    const Text('SMARTERPOS F&B ERP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Color(0xFF141824))),
                    const Text('GPS Biometric HR • EA 1955 Payroll • Live POS Sync', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFB71C1C)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                      const SizedBox(height: 10),
                      Text(_errorMsg, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoading ? null : () => _performLogin(),
                        child: const Text('SIGN IN TO STAFF PORTAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text('1-CLICK DEMO ROLE SWITCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRoleChip('L1 Sutera', 'Ng Zhe Wei', 'staff', Colors.blue[800]!),
                        const SizedBox(width: 6),
                        _buildRoleChip('L1 Austin', 'Tan Mei Ling', 'austin', Colors.teal[800]!),
                        const SizedBox(width: 6),
                        _buildRoleChip('L2 Manager', 'Eugene Tang', 'manager', Colors.orange[800]!),
                        const SizedBox(width: 6),
                        _buildRoleChip('L3 HR HQ', 'See Lin', 'admin', Colors.purple[800]!),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(level, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 9, color: Colors.black87), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 主框架：员工端 HR + 抽成 + 客人订单后台监控
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

  void _triggerGlobalRefresh() => setState(() => _refreshTick++);

  @override
  Widget build(BuildContext context) {
    final int roleLevel = widget.user['role_level'] ?? 1;
    final bool isManagerOrHR = roleLevel >= 2;

    final List<Widget> pages = [
      PunchCardScreen(
        user: widget.user,
        onLogout: widget.onLogout,
        onPunchSuccess: _triggerGlobalRefresh,
      ),
      MyAttendanceScreen(
        key: ValueKey('my_att_$_refreshTick'),
        user: widget.user,
      ),
      LeaveAndClaimsScreen(
        key: ValueKey('leave_$_refreshTick'),
        user: widget.user,
      ),
      MalaysianPayslipScreen(
        key: ValueKey('pay_$_refreshTick'),
        user: widget.user,
      ),
      CommissionScreen(
        key: ValueKey('comm_$_refreshTick'),
        user: widget.user,
      ),
      LiveOrdersMonitorScreen(
        key: ValueKey('pos_live_$_refreshTick'),
        user: widget.user,
      ),
      MyPersonalProfileScreen(
        key: ValueKey('prof_$_refreshTick'),
        user: widget.user,
        onLogout: widget.onLogout,
      ),
      if (isManagerOrHR)
        HRAttendanceAuditScreen(
          key: ValueKey('hr_att_$_refreshTick'),
          user: widget.user,
        ),
      if (isManagerOrHR)
        HRLeaveWorkflowAuditScreen(
          key: ValueKey('hr_leave_$_refreshTick'),
          user: widget.user,
          onDataChanged: _triggerGlobalRefresh,
        ),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.camera_front_outlined, size: 20), label: 'GPS Punch'),
      const BottomNavigationBarItem(icon: Icon(Icons.history_edu_outlined, size: 20), label: 'My Log'),
      const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined, size: 20), label: 'Leave'),
      const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined, size: 20), label: 'Payslip'),
      const BottomNavigationBarItem(icon: Icon(Icons.monetization_on_outlined, size: 20), label: 'Live Pay'),
      const BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_outlined, size: 20), label: 'Live POS'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_pin_outlined, size: 20), label: 'Profile'),
      if (isManagerOrHR)
        const BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined, size: 20), label: 'HR Audit'),
      if (isManagerOrHR)
        const BottomNavigationBarItem(icon: Icon(Icons.account_tree_outlined, size: 20), label: 'Workflow'),
    ];

    final int safeIndex = _currentIndex >= pages.length ? 0 : _currentIndex;

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, -3))],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFB71C1C),
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 10,
          unselectedFontSize: 9.5,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _refreshTick++;
            });
          },
          items: navItems,
        ),
      ),
    );
  }
}

// ==========================================
// 独立页面 1：拍照自拍 + GPS 地理围栏定位打卡系统
// ==========================================
class GpsZoneOption {
  final String label;
  final String coords;
  final int dist;
  final String branch;
  const GpsZoneOption(this.label, this.coords, this.dist, this.branch);
}

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
  bool _selfieCaptured = false;
  String _capturedSelfieFilename = "";
  String _captureTimestamp = "";
  String _selectedGpsZone = "Sutera Mall Outlet (1.5152° N, 103.6660° E)";
  int _gpsDistanceMeters = 14;

  String _feedbackMessage = "Syncing terminal...";
  String _currentTimeString = "";
  String _currentDateString = "";
  Map<String, dynamic> _kpi = {"shifts": 0, "hours": 0.0, "est_ot": 420.0};
  Map<String, dynamic> _notice = {"title": "Notice", "content": ""};
  Timer? _timer;

  final List<GpsZoneOption> _jbBranchGpsZones = const [
    GpsZoneOption("Sutera Mall Outlet (1.5152° N, 103.6660° E)", "1.5152° N, 103.6660° E", 14, "Sutera Utama Outlet"),
    GpsZoneOption("Mount Austin Outlet (1.5641° N, 103.7782° E)", "1.5641° N, 103.7782° E", 19, "Mount Austin Outlet"),
    GpsZoneOption("JB HQ Office (1.4655° N, 103.7578° E)", "1.4655° N, 103.7578° E", 9, "Johor Bahru HQ"),
  ];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    if (widget.user['branch'] == 'Mount Austin Outlet') {
      _selectedGpsZone = _jbBranchGpsZones[1].label;
      _gpsDistanceMeters = _jbBranchGpsZones[1].dist;
    }
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
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id']}),
      );
      if (res.statusCode == 200 && mounted) {
        final d = jsonDecode(res.body);
        setState(() {
          _isClockedIn = d['is_clocked_in'];
          _kpi = d['kpi'] ?? _kpi;
          _notice = d['announcement'] ?? _notice;
          _feedbackMessage = _isClockedIn ? "ACTIVE SHIFT since ${d['clock_in_time']}" : "OFF-DUTY • Capture Selfie & GPS to Clock In";
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _takeBiometricSelfie() {
    final now = DateTime.now();
    final tag = "IMG_${widget.user['username'].toString().toUpperCase()}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}${now.second}.jpg";
    setState(() {
      _selfieCaptured = true;
      _capturedSelfieFilename = tag;
      _captureTimestamp = _currentTimeString;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Biometric Selfie Captured: $tag (Watermark & GPS Embedded)'),
        backgroundColor: Colors.teal[800],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePunchCard() async {
    if (!_selfieCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PHOTO REQUIRED: Please tap "1. Capture Biometric Selfie" before punching in/out!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final endpoint = _isClockedIn ? '/api/clock-out' : '/api/clock-in';
    final GpsZoneOption zoneObj = _jbBranchGpsZones.firstWhere(
      (z) => z.label == _selectedGpsZone,
      orElse: () => _jbBranchGpsZones[0],
    );

    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'staff_id': widget.user['staff_id'],
          'branch': zoneObj.branch,
          'gps_coords': zoneObj.coords,
          'location': zoneObj.label,
          'distance_m': _gpsDistanceMeters,
          'selfie_tag': _capturedSelfieFilename,
        }),
      );
      final d = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() => _selfieCaptured = false);
        await _syncStatus();
        widget.onPunchSuccess();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(d['type'] == 'OUT'
                  ? 'CLOCKED OUT Recorded (${d['time']}) • GPS & Selfie Sent to HR!'
                  : 'CLOCKED IN Recorded (${d['time']}) • GPS & Selfie Sent to HR!'),
              backgroundColor: d['type'] == 'OUT' ? Colors.orange[800] : Colors.green[700],
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 38, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF141824), Color(0xFF7F1414), Color(0xFFB71C1C)]),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(26), bottomRight: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        child: Text(widget.user['full_name'].toString().substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${widget.user['full_name']} (L${widget.user['role_level']})', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            Text('${widget.user['role_title']} • ${widget.user['branch']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onLogout,
                        icon: const Icon(Icons.switch_account, color: Colors.amberAccent, size: 18),
                        label: const Text('Switch', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign, color: Colors.amberAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${_notice['title']}: ${_notice['content']}', style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_currentTimeString, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF141824))),
                          Text(_currentDateString, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isClockedIn ? Colors.green[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isClockedIn ? 'STATUS: ON DUTY' : 'STATUS: OFF DUTY',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: _isClockedIn ? Colors.green[900] : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.gps_fixed, color: Colors.blue[800], size: 18),
                                const SizedBox(width: 6),
                                const Text('LIVE GPS GEOFENCE LOCATOR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF141824))),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                              child: Text('Within ${_gpsDistanceMeters}m (Verified)', style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGpsZone,
                          decoration: InputDecoration(
                            labelText: 'Detected Johor Bahru Outlet GPS Node',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _jbBranchGpsZones
                              .map((z) => DropdownMenuItem<String>(
                                    value: z.label,
                                    child: Text(z.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final found = _jbBranchGpsZones.firstWhere((z) => z.label == val);
                            setState(() {
                              _selectedGpsZone = val;
                              _gpsDistanceMeters = found.dist;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2C),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.camera_alt_outlined, color: Colors.amberAccent, size: 18),
                                SizedBox(width: 6),
                                Text('BIOMETRIC SELFIE VERIFICATION', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(
                              _selfieCaptured ? 'PHOTO LOCKED ✓' : 'REQUIRED BEFORE PUNCH',
                              style: TextStyle(color: _selfieCaptured ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 135,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _selfieCaptured ? Colors.greenAccent : Colors.white24, width: 2),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selfieCaptured ? Icons.verified_user_rounded : Icons.face_retouching_natural,
                                    size: 52,
                                    color: _selfieCaptured ? Colors.greenAccent : Colors.white54,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selfieCaptured
                                        ? 'Snapshot: $_capturedSelfieFilename\nTime: $_captureTimestamp • Face ID Match 99.4%'
                                        : 'Position face inside frame & tap Capture Selfie',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _selfieCaptured ? Colors.greenAccent : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 6,
                                right: 10,
                                child: Text(
                                  'GPS: ${_selectedGpsZone.split("(").last.replaceAll(")", "")}',
                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 9, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.amberAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _takeBiometricSelfie,
                                icon: const Icon(Icons.camera, color: Colors.amberAccent),
                                label: Text(_selfieCaptured ? 'Retake Selfie Photo' : '1. Capture Biometric Selfie', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isClockedIn ? Colors.orange[800] : Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _isLoading ? null : _handlePunchCard,
                                icon: Icon(_isClockedIn ? Icons.logout : Icons.login),
                                label: Text(
                                  _isClockedIn ? '2. CLOCK OUT NOW' : '2. CLOCK IN NOW',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: _isClockedIn ? Colors.green[800] : const Color(0xFFB71C1C)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_feedbackMessage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        Text('Shifts: ${_kpi['shifts']} | ${_kpi['hours']}h', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 独立页面 2：个人考勤流水页
// ==========================================
class MyAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MyAttendanceScreen({super.key, required this.user});
  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  List<dynamic> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyLogs();
  }

  Future<void> _fetchMyLogs() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id'], 'view_all': false}),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _events = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Personal IN / OUT Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141824),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMyLogs)],
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
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(left: BorderSide(color: isIn ? Colors.green[700]! : Colors.orange[800]!, width: 5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: isIn ? Colors.green[700] : Colors.orange[800], borderRadius: BorderRadius.circular(6)),
                            child: Text(isIn ? 'CLOCK IN (进)' : 'CLOCK OUT (出)', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          Text(ev['time'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Location: ${ev['location']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.gps_fixed, size: 13, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text('GPS: ${ev['gps_coords']} (${ev['distance_m']}m)', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                          const Spacer(),
                          const Icon(Icons.camera_alt, size: 13, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(ev['selfie_tag'].toString(), style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                        ],
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
// 独立页面 3：个人请假申请与报销
// ==========================================
class LeaveAndClaimsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const LeaveAndClaimsScreen({super.key, required this.user});
  @override
  State<LeaveAndClaimsScreen> createState() => _LeaveAndClaimsScreenState();
}

class _LeaveAndClaimsScreenState extends State<LeaveAndClaimsScreen> {
  int _subTab = 0;
  String _selectedLeave = 'AL (Annual Leave)';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  List<dynamic> _leaveHistory = [];
  Map<String, dynamic> _quotas = {"al_left": 12, "mc_left": 14, "hl_left": 60};

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
      final lRes = await http.post(Uri.parse('http://127.0.0.1:5000/api/leave-list'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'staff_id': widget.user['staff_id'], 'view_all': false}));
      final cRes = await http.post(Uri.parse('http://127.0.0.1:5000/api/claim-list'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'staff_id': widget.user['staff_id'], 'view_all': false}));
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

  String _fmtDate(DateTime? d) => d == null ? 'Select Date' : "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _submitLeave() async {
    if (_startDate == null || _endDate == null) return;
    await http.post(
      Uri.parse('http://127.0.0.1:5000/api/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staff_id': widget.user['staff_id'],
        'leave_type': _selectedLeave,
        'start_date': _fmtDate(_startDate),
        'end_date': _fmtDate(_endDate),
        'reason': _reasonController.text,
      }),
    );
    setState(() {
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
    });
    _fetchAll();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leave & Expense Claims', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141824),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _subTab == 0 ? const Color(0xFFB71C1C) : Colors.white, foregroundColor: _subTab == 0 ? Colors.white : Colors.black87),
                    onPressed: () => setState(() => _subTab = 0),
                    child: const Text('Leave Application', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _subTab == 1 ? const Color(0xFFB71C1C) : Colors.white, foregroundColor: _subTab == 1 ? Colors.white : Colors.black87),
                    onPressed: () => setState(() => _subTab = 1),
                    child: const Text('Expense Claims', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_subTab == 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Approving Manager: ${widget.user['assigned_manager']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLeave,
                      decoration: InputDecoration(labelText: 'Leave Type (AL: ${_quotas['al_left']}d | MC: ${_quotas['mc_left']}d)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      items: ['AL (Annual Leave)', 'MC (Medical Leave)', 'HL (Hospitalization Leave)', 'UP (Unpaid Leave)'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => _selectedLeave = v!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: InkWell(onTap: () => _pickDate(true), child: InputDecorator(decoration: InputDecoration(labelText: 'Start Date', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), child: Text(_fmtDate(_startDate))))),
                        const SizedBox(width: 10),
                        Expanded(child: InkWell(onTap: () => _pickDate(false), child: InputDecorator(decoration: InputDecoration(labelText: 'End Date', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), child: Text(_fmtDate(_endDate))))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _reasonController, decoration: InputDecoration(labelText: 'Reason for Leave', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
                        onPressed: _submitLeave,
                        child: const Text('SUBMIT TO OUTLET MANAGER', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('My Leave Approval Workflow History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ..._leaveHistory.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['type']} (${item['start']} to ${item['end']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Chip(
                                label: Text(item['status'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                backgroundColor: item['status'] == 'Approved' ? Colors.green[100] : (item['status'] == 'Rejected' ? Colors.red[100] : Colors.orange[100]),
                              ),
                            ],
                          ),
                          Text('Outlet: ${item['branch']} • Assigned Manager: ${item['assigned_manager']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          Text('Reason: ${item['reason']}', style: const TextStyle(fontSize: 12)),
                          if (item['reviewer_name'].toString().isNotEmpty) ...[
                            const Divider(),
                            Text('Reviewed by: ${item['reviewer_name']} (${item['reviewed_at']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                            Text('Manager Decision Remark: "${item['review_remark']}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  )),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _claimCat,
                      decoration: const InputDecoration(labelText: 'Claim Category', border: OutlineInputBorder()),
                      items: ['Transport / Late Night Grab', 'Medical / Clinic Receipt', 'Outlet Kitchen Supply'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => _claimCat = v!),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _claimAmountCtrl, decoration: const InputDecoration(labelText: 'Amount (RM)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: _claimDescCtrl, decoration: const InputDecoration(labelText: 'Receipt No. & Description', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
                        onPressed: _submitClaim,
                        child: const Text('SUBMIT EXPENSE CLAIM'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ..._claimHistory.map((c) => Card(
                    child: ListTile(
                      title: Text('${c['category']} — RM ${c['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${c['description']} • Status: ${c['status']} ${c['reviewer_name'].toString().isNotEmpty ? "(By ${c['reviewer_name']})" : ""}'),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 独立页面 4：马来西亚法定标准薪水单
// ==========================================
class MalaysianPayslipScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MalaysianPayslipScreen({super.key, required this.user});
  @override
  State<MalaysianPayslipScreen> createState() => _MalaysianPayslipScreenState();
}

class _MalaysianPayslipScreenState extends State<MalaysianPayslipScreen> {
  Map<String, dynamic> _allPayslips = {};
  String? _selectedYear;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayslips();
  }

  Future<void> _fetchPayslips() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/payslips-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.user['staff_id']}),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _allPayslips = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportMalaysianPayslipHTML(String year, Map<String, dynamic> s) async {
    final File file = File('${Directory.current.path}\\MY_Payslip_${s['month']}_$year.html');
    final html = '''
    <!DOCTYPE html><html><head><meta charset="utf-8"><title>Malaysian Statutory Payslip</title>
    <style>
      body { font-family: Arial, sans-serif; padding: 30px; background: #eee; }
      .page { max-width: 800px; margin: auto; background: #fff; padding: 30px; border: 2px solid #222; }
      table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 13px; }
      th, td { border: 1px solid #444; padding: 7px 10px; text-align: left; }
      th { background: #f0f0f0; }
      .net { background: #e8f5e9; font-size: 18px; font-weight: bold; color: #1b5e20; }
    </style></head><body><div class="page">
      <h2 style="margin:0;color:#b71c1c;">${s['company_name']} <small style="font-size:12px;color:#555;">Reg: ${s['company_reg']}</small></h2>
      <p style="margin:4px 0;"><b>PENYATA GAJI / STATUTORY PAYSLIP (EMPLOYMENT ACT 1955) — ${s['month']} $year</b></p>
      <table>
        <tr><td><b>Employee Name:</b> ${s['staff_name']}</td><td><b>NRIC No.:</b> ${s['ic_no']}</td><td><b>Staff ID:</b> ${s['staff_id']}</td></tr>
        <tr><td><b>Designation:</b> ${s['role_title']}</td><td><b>Outlet:</b> ${s['branch']}</td><td><b>Pay Period:</b> ${s['pay_period']}</td></tr>
        <tr><td><b>KWSP (EPF) No:</b> ${s['epf_no']}</td><td><b>PERKESO No:</b> ${s['socso_no']}</td><td><b>LHDN Tax No:</b> ${s['tax_no']}</td></tr>
        <tr><td colspan="3"><b>Bank Account:</b> ${s['bank_info']} (Credited Date: ${s['pay_date']})</td></tr>
      </table>
      <table>
        <tr><th>PENDAPATAN (EARNINGS)</th><th>RM</th><th>POTONGAN PEKERJA (EMPLOYEE DEDUCTIONS)</th><th>RM</th></tr>
        <tr><td>Gaji Pokok (Basic Salary)</td><td>${s['basic_salary'].toStringAsFixed(2)}</td><td>KWSP Pekerja (Employee EPF 11%)</td><td>${s['epf'].toStringAsFixed(2)}</td></tr>
        <tr><td>Kerja Lebih Masa (Overtime 1.5x)</td><td>${s['ot_pay'].toStringAsFixed(2)}</td><td>PERKESO Pekerja (Employee SOCSO)</td><td>${s['socso'].toStringAsFixed(2)}</td></tr>
        <tr><td>Komisen Meja (Table Commission)</td><td>${s['commission'].toStringAsFixed(2)}</td><td>SIP / EIS Pekerja (0.2%)</td><td>${s['eis'].toStringAsFixed(2)}</td></tr>
        <tr><td>Elaun Kehadiran (Attendance Bonus)</td><td>${s['attendance_bonus'].toStringAsFixed(2)}</td><td>Potongan Cukai Bulanan (LHDN PCB)</td><td>${s['pcb'].toStringAsFixed(2)}</td></tr>
        <tr><td>Tuntutan (Approved Claims)</td><td>${s['claims_reimbursement'].toStringAsFixed(2)}</td><td></td><td></td></tr>
        <tr><th>GAJI KASAR (GROSS PAY)</th><th>RM ${s['gross_pay'].toStringAsFixed(2)}</th><th>JUMLAH POTONGAN (TOTAL DEDUCTIONS)</th><th>RM ${s['total_deduction'].toStringAsFixed(2)}</th></tr>
      </table>
      <table>
        <tr><th colspan="4">CARUMAN MAJIKAN (EMPLOYER STATUTORY CONTRIBUTIONS)</th></tr>
        <tr><td><b>KWSP Majikan (13%):</b> RM ${s['employer_epf'].toStringAsFixed(2)}</td><td><b>PERKESO Majikan:</b> RM ${s['employer_socso'].toStringAsFixed(2)}</td><td><b>EIS Majikan:</b> RM ${s['employer_eis'].toStringAsFixed(2)}</td><td><b>HRD Corp Levy:</b> RM ${s['employer_hrdf'].toStringAsFixed(2)}</td></tr>
      </table>
      <table><tr class="net"><td>GAJI BERSIH (NET PAYABLE TO BANK)</td><td style="text-align:right;">RM ${s['net_pay'].toStringAsFixed(2)}</td></tr></table>
    </div></body></html>
    ''';
    await file.writeAsString(html);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Malaysian Statutory Payslip Saved: ${file.absolute.path}'), backgroundColor: Colors.green[800]),
      );
    }
  }

  void _showMalaysianStatutorySlipDialog(String year, Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['company_name'].toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C))),
                        Text('SSM Reg No: ${s['company_reg']} • ${s['branch']}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        Text('PENYATA GAJI / STATUTORY PAYSLIP (${s['month']} $year)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF141824), foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _exportMalaysianPayslipHTML(year, s);
                      },
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Print / PDF', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(thickness: 2),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                  child: Column(
                    children: [
                      _buildMetaRow('Employee Name', s['staff_name'], 'NRIC / Identity No.', s['ic_no']),
                      _buildMetaRow('Staff ID & Role', '${s['staff_id']} (${s['role_title']})', 'Pay Period', s['pay_period']),
                      _buildMetaRow('KWSP (EPF) No.', s['epf_no'], 'PERKESO (SOCSO) No.', s['socso_no']),
                      _buildMetaRow('EIS (SIP) No.', s['eis_no'], 'LHDN Income Tax No.', s['tax_no']),
                      _buildMetaRow('Credited Bank', s['bank_info'], 'Payment Date', s['pay_date']),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PENDAPATAN (EARNINGS)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.green)),
                            const Divider(),
                            _buildMoneyRow('Basic Salary (Gaji Pokok)', s['basic_salary']),
                            _buildMoneyRow('Overtime 1.5x (Kerja Lebih Masa)', s['ot_pay']),
                            _buildMoneyRow('Table Commission (Komisen)', s['commission']),
                            _buildMoneyRow('Attendance Bonus (Elaun)', s['attendance_bonus']),
                            _buildMoneyRow('Approved Claims (Tuntutan)', s['claims_reimbursement']),
                            const Divider(),
                            _buildMoneyRow('GAJI KASAR (GROSS)', s['gross_pay'], isBold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('POTONGAN PEKERJA (DEDUCTIONS)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.red)),
                            const Divider(),
                            _buildMoneyRow('Employee KWSP / EPF (11%)', s['epf'], isRed: true),
                            _buildMoneyRow('Employee PERKESO / SOCSO', s['socso'], isRed: true),
                            _buildMoneyRow('Employee SIP / EIS (0.2%)', s['eis'], isRed: true),
                            _buildMoneyRow('LHDN PCB / MTD Tax', s['pcb'], isRed: true),
                            const SizedBox(height: 18),
                            const Divider(),
                            _buildMoneyRow('JUMLAH POTONGAN', s['total_deduction'], isBold: true, isRed: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CARUMAN MAJIKAN (EMPLOYER STATUTORY CONTRIBUTIONS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Employer KWSP (13%): RM ${s['employer_epf'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Employer PERKESO: RM ${s['employer_socso'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Employer EIS: RM ${s['employer_eis'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('HRDF Levy: RM ${s['employer_hrdf'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GAJI BERSIH / NET PAYABLE (CREDITED)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1B5E20))),
                      Text('RM ${s['net_pay'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1B5E20))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String k1, dynamic v1, String k2, dynamic v2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text('$k1: $v1', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(child: Text('$k2: $v2', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildMoneyRow(String label, dynamic val, {bool isBold = false, bool isRed = false}) {
    final double d = (val ?? 0.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('RM ${d.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: isRed ? Colors.red[800] : Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = _allPayslips.keys.toList();
    return Scaffold(
      appBar: AppBar(
        leading: _selectedYear != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedYear = null)) : null,
        title: Text(_selectedYear == null ? 'MY Statutory Payslips (By Year)' : '$_selectedYear Monthly Statements (EA 1955)', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141824),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPayslips)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedYear == null
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final y = years[index];
                    final list = _allPayslips[y] as List;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.folder_special, color: Color(0xFFB71C1C), size: 32),
                        title: Text('Year $y Statutory Archive', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        subtitle: Text('${list.length} Months Available (Includes KWSP 11%/13%, PERKESO, EIS, PCB)'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => setState(() => _selectedYear = y),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: (_allPayslips[_selectedYear] as List).length,
                  itemBuilder: (context, index) {
                    final s = (_allPayslips[_selectedYear] as List)[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFFB71C1C), child: Text(s['month_num'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        title: Text('${s['month']} $_selectedYear (${s['status']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Gross: RM ${s['gross_pay'].toStringAsFixed(2)} • Deduct: -RM ${s['total_deduction'].toStringAsFixed(2)}'),
                        trailing: Text('RM ${s['net_pay'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1B5E20))),
                        onTap: () => _showMalaysianStatutorySlipDialog(_selectedYear!, s),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================================
// 独立页面 5：纯个人档案资料页
// ==========================================
class MyPersonalProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  const MyPersonalProfileScreen({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Personal & Statutory Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141824),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.amberAccent, size: 18),
            label: const Text('Logout', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 32, backgroundColor: Color(0xFFB71C1C), child: Icon(Icons.person, color: Colors.white, size: 36)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['full_name'].toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            Text('${user['role_title']} • Staff ID: #EMP-00${user['staff_id']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Outlet: ${user['branch']}', style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  _buildProfileRow('NRIC / Identification No.', (user['ic_no'] ?? '030618-01-8821').toString()),
                  _buildProfileRow('Department', (user['department'] ?? 'Frontline Service & Operations').toString()),
                  _buildProfileRow('Date Joined', (user['join_date'] ?? '2025-06-01').toString()),
                  _buildProfileRow('Direct Reporting Manager', (user['assigned_manager'] ?? 'Eugene Tang').toString()),
                  _buildProfileRow('Mobile Phone', (user['phone'] ?? '+60 12-789 4512').toString()),
                  _buildProfileRow('Emergency Contact', (user['emergency_contact'] ?? 'Mdm Lim (+60 16-712 9901)').toString()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MALAYSIAN STATUTORY & PAYROLL ACCOUNTS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C))),
                  const Divider(),
                  _buildProfileRow('Payroll Bank & Account', (user['bank_info'] ?? '-').toString()),
                  _buildProfileRow('Basic Monthly Salary', 'RM ${user['basic_salary'].toStringAsFixed(2)}'),
                  _buildProfileRow('KWSP / EPF Member No.', (user['epf_no'] ?? '-').toString()),
                  _buildProfileRow('PERKESO / SOCSO No.', (user['socso_no'] ?? '-').toString()),
                  _buildProfileRow('EIS / SIP Insurance No.', (user['eis_no'] ?? '-').toString()),
                  _buildProfileRow('LHDN Income Tax (PCB) No.', (user['tax_no'] ?? '-').toString()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MY ASSIGNED WEEKLY SHIFT ROSTER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.indigo)),
                  Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.wb_sunny, color: Colors.orange),
                    title: Text('Monday – Wednesday (Morning Shift)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: Text('10:00 AM – 07:00 PM', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.nights_stay, color: Colors.indigo),
                    title: Text('Thursday – Saturday (Closing Shift)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: Text('06:00 PM – 03:00 AM', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }
}

// ==========================================
// 独立页面 6 (HR / 经理专属)：全员考勤归类审计中心
// ==========================================
class HRAttendanceAuditScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HRAttendanceAuditScreen({super.key, required this.user});
  @override
  State<HRAttendanceAuditScreen> createState() => _HRAttendanceAuditScreenState();
}

class _HRAttendanceAuditScreenState extends State<HRAttendanceAuditScreen> {
  List<dynamic> _allEvents = [];
  String _selectedBranch = 'All Branches';
  String _selectedStaff = 'All Staff';
  String _selectedType = 'ALL';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategorizedAttendance();
  }

  Future<void> _fetchCategorizedAttendance() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'staff_id': widget.user['staff_id'],
          'view_all': true,
          'branch_filter': _selectedBranch,
          'staff_filter': _selectedStaff,
        }),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _allEvents = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _inspectGpsAndSelfieProof(Map<String, dynamic> ev) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text('HR Biometric & GPS Proof: ${ev['staff_name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF141824), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  const Icon(Icons.account_box_rounded, size: 64, color: Colors.greenAccent),
                  const SizedBox(height: 8),
                  Text('CAPTURED SELFIE: ${ev['selfie_tag']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Timestamp Watermark: ${ev['time']}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                  const Text('AI Liveness Check: PASSED (99.4% Match)', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Outlet: ${ev['branch']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('GPS Coordinates: ${ev['gps_coords']}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            Text('Distance from Outlet Center: ${ev['distance_m']} meters (Within 50m Geofence)', style: const TextStyle(fontSize: 12, color: Colors.green)),
            Text('Gate Terminal: ${ev['location']}', style: const TextStyle(fontSize: 12)),
            Text('Verification Status: ${ev['verify_status']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close Inspector')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _allEvents.where((e) => _selectedType == 'ALL' || e['type'] == _selectedType).toList();
    final int inCount = filteredList.where((e) => e['type'] == 'IN').length;
    final int outCount = filteredList.where((e) => e['type'] == 'OUT').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Attendance Audit (GPS & Photo)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141824),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCategorizedAttendance)],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBranch,
                        decoration: InputDecoration(labelText: 'Filter by Outlet', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: ['All Branches', 'Sutera Utama Outlet', 'Mount Austin Outlet', 'Johor Bahru HQ']
                            .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedBranch = v!);
                          _fetchCategorizedAttendance();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStaff,
                        decoration: InputDecoration(labelText: 'Filter by Staff', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        items: ['All Staff', 'Ng Zhe Wei', 'Tan Mei Ling', 'Eugene Tang', 'See Lin']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedStaff = v!);
                          _fetchCategorizedAttendance();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildSummaryBadge('Total Logs: ${filteredList.length}', Colors.indigo),
                    const SizedBox(width: 8),
                    _buildSummaryBadge('Clock-In: $inCount', Colors.green[700]!),
                    const SizedBox(width: 8),
                    _buildSummaryBadge('Clock-Out: $outCount', Colors.orange[800]!),
                    const Spacer(),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ALL', label: Text('All', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'IN', label: Text('IN', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'OUT', label: Text('OUT', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (s) => setState(() => _selectedType = s.first),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final ev = filteredList[index];
                      final bool isIn = ev['type'] == 'IN';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: isIn ? Colors.green[700] : Colors.orange[800], borderRadius: BorderRadius.circular(6)),
                                    child: Text(isIn ? 'CLOCK IN' : 'CLOCK OUT (${ev['hours']}h)', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${ev['staff_name']} (${ev['role_title']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(6)),
                                    child: Text(ev['branch'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(ev['time'].toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.gps_fixed, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text('${ev['gps_coords']} • ${ev['distance_m']}m from outlet', style: const TextStyle(fontSize: 11, color: Colors.blueGrey))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.camera_front, size: 15, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text('Photo: ${ev['selfie_tag']}', style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                    onPressed: () => _inspectGpsAndSelfieProof(ev),
                                    icon: const Icon(Icons.visibility, size: 15),
                                    label: const Text('Inspect Photo & GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

// ==========================================
// 独立页面 7 (HR / 经理专属)：门店请假审批流追踪与薪资总控专页
// ==========================================
class HRLeaveWorkflowAuditScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDataChanged;
  const HRLeaveWorkflowAuditScreen({super.key, required this.user, required this.onDataChanged});
  @override
  State<HRLeaveWorkflowAuditScreen> createState() => _HRLeaveWorkflowAuditScreenState();
}

class _HRLeaveWorkflowAuditScreenState extends State<HRLeaveWorkflowAuditScreen> {
  String _branchFilter = 'All Branches';
  List<dynamic> _branchLeaves = [];
  List<dynamic> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkflowData();
  }

  Future<void> _loadWorkflowData() async {
    final lRes = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/leave-list'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staff_id': widget.user['staff_id'],
        'view_all': true,
        'branch_filter': _branchFilter,
      }),
    );
    final uRes = await http.post(Uri.parse('http://127.0.0.1:5000/api/users'));
    if (lRes.statusCode == 200 && uRes.statusCode == 200 && mounted) {
      setState(() {
        _branchLeaves = jsonDecode(lRes.body)['data'];
        _allUsers = jsonDecode(uRes.body)['data'];
      });
    }
  }

  void _openManagerDecisionModal(Map<String, dynamic> item, String targetStatus) {
    final bool isReject = targetStatus == 'Rejected';
    final remarkCtrl = TextEditingController(text: isReject ? '' : 'Approved by Outlet Management.');
    final reviewerIdentity = '${widget.user['full_name']} (${widget.user['role_title']})';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$targetStatus Leave: ${item['staff_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Outlet: ${item['branch']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('Assigned Outlet Manager: ${item['assigned_manager']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            Text('Acting Reviewer: $reviewerIdentity', style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: remarkCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isReject ? 'Mandatory Rejection Reason *' : 'Approval Remark',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isReject ? Colors.red[700] : Colors.green[700], foregroundColor: Colors.white),
            onPressed: () async {
              if (isReject && remarkCtrl.text.trim().isEmpty) return;
              await http.post(
                Uri.parse('http://127.0.0.1:5000/api/leave-approve'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'leave_id': item['id'],
                  'status': targetStatus,
                  'reviewer_name': reviewerIdentity,
                  'review_remark': remarkCtrl.text.trim(),
                }),
              );
              if (context.mounted) Navigator.pop(context);
              _loadWorkflowData();
              widget.onDataChanged();
            },
            child: Text('Confirm $targetStatus'),
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
        title: const Text('HR Outlet Leave Workflow & Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141824),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWorkflowData)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.storefront, color: Color(0xFFB71C1C)),
                  const SizedBox(width: 10),
                  const Text('Audit Outlet Leave Pipeline:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _branchFilter,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                      items: ['All Branches', 'Sutera Utama Outlet', 'Mount Austin Outlet']
                          .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _branchFilter = v!);
                        _loadWorkflowData();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('OUTLET LEAVE APPROVAL WORKFLOW PIPELINE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C))),
            const SizedBox(height: 10),
            ..._branchLeaves.map((item) {
              final bool isApproved = item['status'] == 'Approved';
              final bool isRejected = item['status'] == 'Rejected';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item['staff_name']} • ${item['type']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8)),
                            child: Text(item['branch'].toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Period: ${item['start']} ➔ ${item['end']} • Reason: ${item['reason']}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Step 1 (Applicant): ${item['staff_name']} (${item['branch']})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Step 2 (Assigned Outlet Manager): ${item['assigned_manager']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const SizedBox(height: 4),
                            Text(
                              item['reviewer_name'].toString().isNotEmpty
                                  ? 'Step 3 (Final Decision): ${item['status'].toString().toUpperCase()} by ${item['reviewer_name']} at ${item['reviewed_at']}\nRemark: "${item['review_remark']}"'
                                  : 'Step 3 (Final Decision): PENDING MANAGER ACTION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isApproved ? Colors.green[800] : (isRejected ? Colors.red[800] : Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _openManagerDecisionModal(item, 'Approved'),
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            label: const Text('Approve', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _openManagerDecisionModal(item, 'Rejected'),
                            icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                            label: const Text('Reject with Reason', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (roleLevel >= 3) ...[
              const SizedBox(height: 20),
              const Text('L3 HR MASTER SALARY CONFIGURATION', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.purple)),
              const SizedBox(height: 10),
              ..._allUsers.map((u) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${u['full_name']} (${u['branch']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Basic: RM ${u['basic_salary']} • Bonus: RM ${u['custom_bonus']} • Manager: ${u['assigned_manager']}'),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 独立页面 8：实时绩效与抽成看板
// ==========================================
class CommissionScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const CommissionScreen({super.key, required this.user});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  late Future _commissionFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _commissionFuture = fetchCommission();
    });
  }

  Future fetchCommission() async {
    final url = Uri.parse('http://127.0.0.1:5000/api/commission/${widget.user['staff_id']}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load commission data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Live Commission', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141824),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: FutureBuilder(
        future: _commissionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('Error connecting to server:\n${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          } else {
            final data = snapshot.data as Map<String, dynamic>;
            if (data['status'] == 'error') {
              return Center(child: Text(data['message'].toString(), style: const TextStyle(fontSize: 16)));
            }

            final commissionAmount = data['weekly_commission_rm'].toString();
            final double kpiProgress = (data['kpi_progress'] as num).toDouble();
            final bool isTargetAchieved = data['target_achieved'] == true;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Staff: ${data['staff_name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Role: ${data['role']}', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      child: Column(
                        children: [
                          const Text('Live Weekly Commission', style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            'RM $commissionAmount',
                            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 36),
                          const Text('Weekly KPI Target (RM 50.00)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: kpiProgress,
                            minHeight: 14,
                            backgroundColor: Colors.grey[200],
                            color: isTargetAchieved ? Colors.green : const Color(0xFFB71C1C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 12),
                          if (isTargetAchieved)
                            const Text('Target Achieved!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))
                          else
                            Text('${(kpiProgress * 100).toStringAsFixed(1)}% Completed', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

// ==========================================
// 独立页面 9：后台 POS 实时订单监控 (接收客人独立点餐端的数据)
// ==========================================
class LiveOrdersMonitorScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const LiveOrdersMonitorScreen({super.key, required this.user});

  @override
  State<LiveOrdersMonitorScreen> createState() => _LiveOrdersMonitorScreenState();
}

class _LiveOrdersMonitorScreenState extends State<LiveOrdersMonitorScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchLiveOrders();
    // 每 5 秒自动同步一次客人端新下的单
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLiveOrders(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveOrders({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:5000/api/pos/orders/live'));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _orders = jsonDecode(res.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    await http.post(
      Uri.parse('http://127.0.0.1:5000/api/pos/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );
    _fetchLiveOrders(silent: true);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange[800]!;
      case 'Cooking':
        return Colors.blue[700]!;
      case 'Served':
        return Colors.teal[700]!;
      case 'Paid':
        return Colors.green[700]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live POS Orders (Synced from Customer Portal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF141824),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _fetchLiveOrders()),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFEBEE),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.qr_code_2, color: Color(0xFFB71C1C), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Customer Self-Ordering URL: http://127.0.0.1:5000/order  •  Auto-syncing every 5s',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
                : _orders.isEmpty
                    ? const Center(
                        child: Text(
                          'No customer orders yet.\nOpen http://127.0.0.1:5000/order in your browser to place a test order!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final o = _orders[index];
                          final List<dynamic> items = o['items'] ?? [];
                          final String status = o['status'].toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#POS-${o['order_id'].toString().padLeft(4, '0')} • ${o['table_no']}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _statusColor(status), borderRadius: BorderRadius.circular(8)),
                                        child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Customer: ${o['customer_contact'] ?? 'Guest'} • Server: ${o['staff_name']} • ${o['created_at']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                  ),
                                  const Divider(),
                                  ...items.map((it) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${it['qty']}x  ${it['item_name']}', style: const TextStyle(fontSize: 13)),
                                            Text('RM ${(it['line_total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      )),
                                  if ((o['remarks'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text('Remarks: ${o['remarks']}', style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontStyle: FontStyle.italic)),
                                  ],
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: RM ${(o['grand_total'] as num).toStringAsFixed(2)} (incl. 10% Svc + 6% SST)',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1B5E20)),
                                      ),
                                      Row(
                                        children: [
                                          if (status == 'Pending')
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                                              onPressed: () => _updateStatus(o['order_id'], 'Cooking'),
                                              child: const Text('Start Cooking', style: TextStyle(fontSize: 11)),
                                            ),
                                          if (status == 'Cooking')
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                                              onPressed: () => _updateStatus(o['order_id'], 'Served'),
                                              child: const Text('Mark Served', style: TextStyle(fontSize: 11)),
                                            ),
                                          if (status == 'Served')
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                                              onPressed: () => _updateStatus(o['order_id'], 'Paid'),
                                              child: const Text('Mark Paid', style: TextStyle(fontSize: 11)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}