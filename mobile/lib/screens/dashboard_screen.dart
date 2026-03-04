import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/demo_data.dart';
import '../widgets/premium_widgets.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'dm_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<dynamic> _courses = [];
  bool _loading = true;
  int _tab = 0;
  String _search = '';
  final _demo = DemoData();

  // Desktop: selected chat
  String? _selId;
  String? _selTitle;
  bool _selActive = true;

  // Desktop: selected DM
  String? _dmId;
  String? _dmName;

  late AnimationController _cardAnim;

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fetch();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      setState(() {
        _courses = _demo.getCourses(auth.role, auth.userId);
        _loading = false;
      });
      _cardAnim.forward(from: 0);
      return;
    }
    try {
      final r = await http.get(Uri.parse('${auth.baseUrl}/courses'),
          headers: {'Authorization': 'Bearer ${auth.token}'});
      if (r.statusCode == 200) {
        setState(() {
          _courses = jsonDecode(r.body);
          _loading = false;
        });
        _cardAnim.forward(from: 0);
      }
    } catch (e) {
      debugPrint('$e');
      setState(() => _loading = false);
    }
  }

  // ── CRUD ──
  Future<void> _createCourse(String name, String code, String sem,
      String roomId, String roomPass) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      _demo.addCourse(
          name: name,
          code: code,
          semester: sem,
          roomId: roomId,
          roomPass: roomPass,
          teacherName: auth.userName ?? 'Teacher',
          teacherId: auth.userId ?? '');
      _fetch();
      if (mounted) Navigator.pop(context);
      return;
    }
    try {
      final r = await http.post(Uri.parse('${auth.baseUrl}/courses'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${auth.token}'
          },
          body: jsonEncode({
            'name': name,
            'code': code,
            'semester': sem,
            'chatRoomId': roomId,
            'chatPassword': roomPass,
          }));
      if (r.statusCode == 201) {
        _fetch();
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          final error = jsonDecode(r.body)['error'] ?? 'Failed to create room';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }
    } catch (e) {
      debugPrint('$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Network Error. Please try again.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _join(String roomId, String pass) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      final c = _demo.joinCourse(roomId, pass);
      if (c != null) {
        _fetch();
        if (mounted) Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Room not found or wrong password',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
      return;
    }
    try {
      final r = await http.post(Uri.parse('${auth.baseUrl}/enroll'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${auth.token}'
          },
          body: jsonEncode({'chatRoomId': roomId, 'chatPassword': pass}));
      if (r.statusCode == 201) {
        _fetch();
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          final error = jsonDecode(r.body)['error'] ?? 'Failed to join room';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }
    } catch (e) {
      debugPrint('$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Network Error. Please try again.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ── Sorting + filtering ──
  List<dynamic> get _filtered {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // Tab 0 = Ongoing (active), Tab 1 = Messages (DM), Tab 2 = Previous (inactive)
    final list = _courses.where((c) {
      final s = c['sections'] as List?;
      if (s == null || s.isEmpty) return false;
      final active = s[0]['isActive'] ?? true;
      if (_tab == 0 ? !active : active) return false;
      if (_search.isNotEmpty) {
        final n = (c['name'] ?? '').toString().toLowerCase();
        final cd = (c['code'] ?? '').toString().toLowerCase();
        return n.contains(_search) || cd.contains(_search);
      }
      return true;
    }).toList();
    if (_demo.isDemoUser(auth.token)) {
      list.sort((a, b) {
        final aId = a['sections']?[0]?['id'];
        final bId = b['sections']?[0]?['id'];
        final aT =
            (aId != null ? _demo.getLastMessage(aId) : null)?['createdAt'] ??
                '';
        final bT =
            (bId != null ? _demo.getLastMessage(bId) : null)?['createdAt'] ??
                '';
        return bT.compareTo(aT);
      });
    }
    return list;
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }

  static const _avatarColors = [
    Color(0xFF78716C),
    Color(0xFF6B7280),
    Color(0xFF92400E),
    Color(0xFF065F46),
    Color(0xFF1E40AF),
    Color(0xFF6D28D9),
    Color(0xFF9D174D),
    Color(0xFF0E7490),
  ];

  Color _avColor(int i) => _avatarColors[i % _avatarColors.length];

  // ═══════════════════════════════════════════
  //  BUILD — adaptive layout
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2EF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth >= 840) {
              return _desktop(auth, box);
            }
            return _mobile(auth);
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  //  DESKTOP: sidebar + content
  // ─────────────────────────────────────
  Widget _desktop(AuthProvider auth, BoxConstraints box) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // ── Sidebar ──
          SizedBox(
            width: 340,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE8E8E5))),
              ),
              child: Column(
                children: [
                  _sidebarHeader(auth),
                  _searchBar(),
                  _tabBar(),
                  const Divider(height: 1, color: Color(0xFFE8E8E5)),
                  Expanded(
                      child: _tab == 1
                          ? _dmList(auth, desktop: true)
                          : _courseList(auth, desktop: true)),
                ],
              ),
            ),
          ),
          // ── Content ──
          Expanded(
            child: _dmId != null
                ? DMChatScreen(
                    key: ValueKey('dm-$_dmId'),
                    recipientId: _dmId!,
                    recipientName: _dmName ?? '',
                    embedded: true,
                    onBack: () => setState(() => _dmId = null),
                  )
                : _selId != null
                    ? ChatScreen(
                        key: ValueKey(_selId),
                        sectionId: _selId!,
                        title: _selTitle ?? '',
                        isActive: _selActive,
                        embedded: true,
                        onBack: () => setState(() => _selId = null),
                      )
                    : _emptyContent(),
          ),
        ],
      ),
    );
  }

  Widget _sidebarHeader(AuthProvider auth) {
    final isTeacher = auth.role == 'TEACHER' || auth.role == 'ADMIN';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.school_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text('DIU Connect',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5)),
          ),
          _iconBtn(
            icon: isTeacher ? Icons.add_rounded : Icons.group_add_rounded,
            color: AppTheme.accent,
            onTap: isTeacher ? _showCreate : _showJoin,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ProfileScreen(),
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                  transitionsBuilder: (_, a, __, c) => FadeTransition(
                      opacity:
                          CurvedAnimation(parent: a, curve: Curves.easeOut),
                      child: c),
                )),
            child: Hero(
              tag: 'profile-avatar',
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.charcoal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    (auth.userName ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(9),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 16, color: AppTheme.textLight),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 9),
          ),
        ),
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pillW = (constraints.maxWidth) / 3;
            return Stack(
              children: [
                // Sliding indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: _tab * pillW,
                  top: 0,
                  bottom: 0,
                  width: pillW,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _pill('Ongoing', 0),
                    _pill('Messages', 1),
                    _pill('Previous', 2),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pill(String label, int idx) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tab = idx);
          _cardAnim.forward(from: 0);
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? AppTheme.textDark : AppTheme.textLight),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyContent() {
    return Container(
      color: const Color(0xFFFAFAF8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.forum_outlined,
                  size: 28, color: AppTheme.borderStrong),
            ),
            const SizedBox(height: 16),
            Text('Select a course',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text('Choose a conversation from the sidebar',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  //  MOBILE: full-screen list
  // ─────────────────────────────────────
  Widget _mobile(AuthProvider auth) {
    return Column(
      children: [
        _mobileHeader(auth),
        Expanded(
            child: _tab == 1
                ? _dmList(auth, desktop: false)
                : _courseList(auth, desktop: false)),
      ],
    );
  }

  Widget _mobileHeader(AuthProvider auth) {
    final isTeacher = auth.role == 'TEACHER' || auth.role == 'ADMIN';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('DIU Connect',
                    style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5)),
              ),
              GestureDetector(
                onTap: isTeacher ? _showCreate : _showJoin,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isTeacher
                              ? Icons.add_rounded
                              : Icons.group_add_rounded,
                          color: Colors.white,
                          size: 16),
                      const SizedBox(width: 3),
                      Text(isTeacher ? 'New' : 'Join',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ProfileScreen(),
                      transitionDuration: const Duration(milliseconds: 250),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 200),
                      transitionsBuilder: (_, a, __, c) => FadeTransition(
                          opacity:
                              CurvedAnimation(parent: a, curve: Curves.easeOut),
                          child: c),
                    )),
                child: Hero(
                  tag: 'profile-avatar',
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        (auth.userName ?? 'U')[0].toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppTheme.textLight),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _tabBar(),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  //  SHARED: DM conversation list
  // ─────────────────────────────────────
  Widget _dmList(AuthProvider auth, {required bool desktop}) {
    if (!_demo.isDemoUser(auth.token)) {
      return const Center(child: Text('DMs not available'));
    }
    final convos = _demo.getDMConversations(auth.userId ?? '');
    if (convos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 36, color: AppTheme.borderStrong),
              const SizedBox(height: 12),
              Text('No messages yet',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMid)),
              const SizedBox(height: 4),
              Text('Direct messages will appear here',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textLight)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: desktop ? 16 : 80),
      itemCount: convos.length,
      itemBuilder: (_, i) {
        final c = convos[i];
        final name = c['partnerName'] ?? 'Unknown';
        final lastMsg = c['lastMessage'] ?? '';
        final time = _relativeTime(c['lastTime']);
        final color = _avColor(i);

        return GestureDetector(
          onTap: () {
            if (desktop) {
              setState(() {
                _dmId = c['partnerId'];
                _dmName = name;
                _selId = null;
              });
            } else {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => DMChatScreen(
                    recipientId: c['partnerId'],
                    recipientName: name,
                  ),
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                  transitionsBuilder: (_, a, __, ch) => SlideTransition(
                    position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                        .animate(
                            CurvedAnimation(parent: a, curve: Curves.easeOut)),
                    child: ch,
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: desktop ? 10 : 16, vertical: desktop ? 3 : 5),
            padding: EdgeInsets.all(desktop ? 12 : 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFFE8E8E5).withOpacity(0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Premium avatar
                Container(
                  width: desktop ? 44 : 50,
                  height: desktop ? 44 : 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.08),
                        color.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: color.withOpacity(0.12), width: 1),
                  ),
                  child: Center(
                    child: Text(name[0].toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: desktop ? 17 : 19,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ),
                SizedBox(width: desktop ? 12 : 14),
                // Name + preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: desktop ? 14 : 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text(lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppTheme.textLight,
                              height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Time badge
                if (time.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(time,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textLight)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────
  //  SHARED: course list
  // ─────────────────────────────────────
  Widget _courseList(AuthProvider auth, {required bool desktop}) {
    if (_loading) return const Center(child: PremiumSpinner());
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  _tab == 2
                      ? Icons.inventory_2_outlined
                      : Icons.auto_stories_outlined,
                  size: 36,
                  color: AppTheme.borderStrong),
              const SizedBox(height: 12),
              Text(_tab == 2 ? 'No previous courses' : 'No ongoing courses',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMid)),
              const SizedBox(height: 4),
              Text(
                  _tab == 0
                      ? (auth.role == 'TEACHER'
                          ? 'Create a course to get started'
                          : 'Join a room to get started')
                      : 'Completed courses appear here',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textLight)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 4, bottom: desktop ? 16 : 80),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final delay = (i * 0.1).clamp(0.0, 0.5);
        final end = (delay + 0.35).clamp(0.0, 1.0);
        final anim = CurvedAnimation(
          parent: _cardAnim,
          curve: Interval(delay, end, curve: Curves.easeOut),
        );
        return FadeTransition(
          opacity: anim,
          child: _courseRow(list[i], i, auth, desktop: desktop),
        );
      },
    );
  }

  // ── Parse course code into letters and numbers ──
  Map<String, String> _splitCode(String code) {
    final letters = code.replaceAll(RegExp(r'[0-9]'), '');
    final numbers = code.replaceAll(RegExp(r'[^0-9]'), '');
    return {'letters': letters, 'numbers': numbers};
  }

  Widget _courseRow(dynamic course, int idx, AuthProvider auth,
      {required bool desktop}) {
    final name = course['name'] ?? '';
    final code = course['code'] ?? '';
    final teacher = course['teacher']?['name'] ?? '';
    final secId = course['sections']?[0]?['id'];
    final isActive = course['sections']?[0]?['isActive'] ?? true;
    final color = _avColor(idx);
    final selected = desktop && secId == _selId;
    final codeParts = _splitCode(code);

    String preview = '';
    String time = '';
    if (secId != null && _demo.isDemoUser(auth.token)) {
      final last = _demo.getLastMessage(secId);
      if (last != null) {
        final fn = (last['sender']?['name'] ?? '').split(' ').first;
        preview = '$fn: ${last['content']}';
        time = _relativeTime(last['createdAt']);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: secId == null
            ? null
            : () {
                if (desktop) {
                  setState(() {
                    _selId = secId;
                    _selTitle = name;
                    _selActive = isActive;
                  });
                } else {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ChatScreen(
                          sectionId: secId, title: name, isActive: isActive),
                      transitionDuration: const Duration(milliseconds: 240),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 180),
                      transitionsBuilder: (_, a, __, child) => FadeTransition(
                          opacity:
                              CurvedAnimation(parent: a, curve: Curves.easeOut),
                          child: child),
                    ),
                  ).then((_) => _fetch());
                }
              },
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: desktop ? 10 : 16, vertical: desktop ? 3 : 5),
          padding: EdgeInsets.all(desktop ? 12 : 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(
                    color: AppTheme.accent.withOpacity(0.25), width: 1.5)
                : Border.all(color: const Color(0xFFE8E8E5).withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(selected ? 0.05 : 0.03),
                blurRadius: selected ? 12 : 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Premium course code avatar ──
              Container(
                width: desktop ? 48 : 54,
                height: desktop ? 48 : 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.08),
                      color.withOpacity(0.16),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.12), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      codeParts['letters'] ?? '',
                      style: GoogleFonts.inter(
                          fontSize: desktop ? 13 : 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                          height: 1.1),
                    ),
                    if ((codeParts['numbers'] ?? '').isNotEmpty)
                      Text(
                        codeParts['numbers']!,
                        style: GoogleFonts.inter(
                            fontSize: desktop ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: color.withOpacity(0.7),
                            letterSpacing: 0.3,
                            height: 1.2),
                      ),
                  ],
                ),
              ),
              SizedBox(width: desktop ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: desktop ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                  letterSpacing: -0.2)),
                        ),
                        if (time.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(time,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textLight)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(code,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color.withOpacity(0.8))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(teacher,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppTheme.textLight)),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFFDE68A), width: 0.5),
                            ),
                            child: Text('Ended',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E))),
                          ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppTheme.textLight,
                              height: 1.3)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Premium Dialogs ──

  void _showCreate() {
    final n = TextEditingController();
    final c = TextEditingController();
    final s = TextEditingController(text: 'Spring 2026');
    final ri = TextEditingController();
    final rp = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 440,
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.add_home_work_rounded,
                                color: Color(0xFF111827), size: 28),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF9CA3AF)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Course',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set up a new communication room for your students. They will need the Room ID and Password to join.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _premiumField(n, 'Course Name', Icons.menu_book_rounded),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child:
                                  _premiumField(c, 'Course Code', Icons.tag)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _premiumField(
                                  s, 'Semester', Icons.date_range_rounded)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chat Room Credentials',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4B5563),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                    child: _premiumField(ri, 'Room ID',
                                        Icons.meeting_room_rounded)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _premiumField(
                                        rp, 'Password', Icons.lock_rounded,
                                        obscure: true)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: isCreating
                            ? null
                            : () async {
                                if (n.text.isNotEmpty &&
                                    c.text.isNotEmpty &&
                                    ri.text.isNotEmpty &&
                                    rp.text.isNotEmpty) {
                                  setModalState(() => isCreating = true);
                                  await _createCourse(
                                      n.text, c.text, s.text, ri.text, rp.text);
                                  if (mounted) {
                                    setModalState(() => isCreating = false);
                                  }
                                }
                              },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Center(
                            child: isCreating
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Create Course Room',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showJoin() {
    final ri = TextEditingController();
    final rp = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 400,
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.sensor_door_rounded,
                              color: Color(0xFF15803D), size: 28),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF9CA3AF)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Join Room',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the credentials provided by your teacher to connect to the class.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _premiumField(ri, 'Room ID', Icons.meeting_room_rounded),
                    const SizedBox(height: 16),
                    _premiumField(rp, 'Password', Icons.lock_rounded,
                        obscure: true),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: isJoining
                          ? null
                          : () async {
                              if (ri.text.isNotEmpty && rp.text.isNotEmpty) {
                                setModalState(() => isJoining = true);
                                await _join(ri.text, rp.text);
                                if (mounted) {
                                  setModalState(() => isJoining = false);
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please fill all fields')),
                                );
                              }
                            },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Center(
                          child: isJoining
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Join Course',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _premiumField(TextEditingController ctl, String hint, IconData icon,
      {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: ctl,
        obscureText: obscure,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          icon: Icon(icon, size: 22, color: const Color(0xFF9CA3AF)),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF9CA3AF),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
