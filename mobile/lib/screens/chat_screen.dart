import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/demo_data.dart';
import 'room_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final String sectionId;
  final String title;
  final bool isActive;
  final bool embedded; // true = inside desktop split panel
  final VoidCallback? onBack;

  const ChatScreen({
    super.key,
    required this.sectionId,
    required this.title,
    this.isActive = true,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtl = TextEditingController();
  final _scroll = ScrollController();
  List<dynamic> _msgs = [];
  int _memberCount = 0;
  Timer? _poll;
  int _cd = 0;
  Timer? _cdTimer;
  bool _first = true;
  final _demo = DemoData();
  late AnimationController _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350))
      ..forward();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cdTimer?.cancel();
    _scroll.dispose();
    _msgCtl.dispose();
    _entryAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      final data = _demo.getMessages(widget.sectionId);
      final prev = _msgs.length;
      setState(() {
        _msgs = data;
        _memberCount = _demo.getMembers(widget.sectionId).length;
      });
      if (_first || data.length > prev) {
        _first = false;
        _bottom();
      }
      return;
    }
    try {
      final r = await http.get(
        Uri.parse('${auth.baseUrl}/messages?sectionId=${widget.sectionId}'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final prev = _msgs.length;
        setState(() => _msgs = data);
        if (_first || data.length > prev) {
          _first = false;
          _bottom();
        }
      }
    } catch (_) {}
  }

  void _bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    if (_msgCtl.text.trim().isEmpty || _cd > 0) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txt = _msgCtl.text.trim();
    _msgCtl.clear();
    if (_demo.isDemoUser(auth.token)) {
      _demo.addMessage(
          widget.sectionId, txt, auth.userId ?? '', auth.userName ?? '');
      _load();
      if (auth.role == 'STUDENT') _startCd();
      return;
    }
    try {
      final r = await http.post(
        Uri.parse('${auth.baseUrl}/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}'
        },
        body: jsonEncode({'content': txt, 'sectionId': widget.sectionId}),
      );
      if (r.statusCode == 201) {
        _load();
        if (auth.role == 'STUDENT') _startCd();
      } else if (r.statusCode == 429 && mounted) {
        _snack('Wait 30s between messages');
      }
    } catch (_) {}
  }

  void _startCd() {
    setState(() => _cd = 30);
    _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_cd > 0) {
          _cd--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      backgroundColor: AppTheme.warning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _fmtTime(String s) {
    try {
      return DateFormat.jm().format(DateTime.parse(s).toLocal());
    } catch (_) {
      return '';
    }
  }

  String? _dateLabel(int i) {
    try {
      final cur = DateTime.parse(_msgs[i]['createdAt']).toLocal();
      if (i == 0) return DateFormat('MMMM d, y').format(cur);
      final prev = DateTime.parse(_msgs[i - 1]['createdAt']).toLocal();
      if (cur.day != prev.day ||
          cur.month != prev.month ||
          cur.year != prev.year) {
        final now = DateTime.now();
        if (cur.day == now.day &&
            cur.month == now.month &&
            cur.year == now.year) {
          return 'Today';
        }
        return DateFormat('MMMM d, y').format(cur);
      }
    } catch (_) {}
    return null;
  }

  // Sender colors — muted tones
  static const _senderColors = [
    Color(0xFF065F46),
    Color(0xFF92400E),
    Color(0xFF1E40AF),
    Color(0xFF6D28D9),
    Color(0xFF9D174D),
    Color(0xFF0E7490),
    Color(0xFF78716C),
  ];

  Color _senderColor(String? id) {
    if (id == null) return _senderColors[0];
    return _senderColors[id.hashCode.abs() % _senderColors.length];
  }

  // ═══════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final content = Column(
      children: [
        _topBar(auth),
        Expanded(child: _messageArea(auth)),
        if (widget.isActive) _inputBar(),
        if (!widget.isActive) _endedBanner(),
      ],
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: content),
    );
  }

  // ── Top bar ──
  Widget _topBar(AuthProvider auth) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(color: AppTheme.border.withOpacity(0.6))),
        ),
        child: Row(
          children: [
            if (!widget.embedded)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: AppTheme.textDark),
                onPressed: () => Navigator.pop(context),
              ),
            if (widget.embedded) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.isActive
                              ? AppTheme.success
                              : AppTheme.textLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isActive
                            ? '$_memberCount members'
                            : 'Ended · $_memberCount members',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded,
                  size: 20, color: AppTheme.textLight),
              onPressed: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => RoomDetailsScreen(
                      sectionId: widget.sectionId,
                      title: widget.title,
                      isActive: widget.isActive),
                  transitionDuration: const Duration(milliseconds: 240),
                  reverseTransitionDuration: const Duration(milliseconds: 180),
                  transitionsBuilder: (_, a, __, child) => FadeTransition(
                    opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message area ──
  Widget _messageArea(AuthProvider auth) {
    if (_msgs.isEmpty) {
      return Container(
        color: const Color(0xFFFAFAF8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined,
                  size: 32, color: AppTheme.borderStrong),
              const SizedBox(height: 10),
              Text('No messages yet',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMid)),
              const SizedBox(height: 3),
              Text(
                widget.isActive
                    ? 'Start the conversation'
                    : 'This class has ended',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFFAFAF8),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        itemCount: _msgs.length,
        itemBuilder: (_, i) => _buildMsg(auth, i),
      ),
    );
  }

  Widget _buildMsg(AuthProvider auth, int i) {
    final m = _msgs[i];
    final me = m['senderId'] == auth.userId;
    final name = m['sender']?['name'] ?? 'Unknown';
    final time = _fmtTime(m['createdAt'] ?? '');
    final isNewSender = i == 0 || _msgs[i - 1]['senderId'] != m['senderId'];
    final dLabel = _dateLabel(i);
    final sColor = _senderColor(m['senderId']);

    return Column(
      children: [
        // Date divider
        if (dLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              Expanded(child: Container(height: 1, color: AppTheme.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(dLabel,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textLight,
                        letterSpacing: 0.2)),
              ),
              Expanded(child: Container(height: 1, color: AppTheme.border)),
            ]),
          ),
        // Message row
        Padding(
          padding: EdgeInsets.only(top: !me && isNewSender ? 14 : 2, bottom: 1),
          child: me
              ? _myBubble(m, time)
              : _otherBubble(m, name, time, isNewSender, sColor),
        ),
      ],
    );
  }

  double _bubbleSpacer(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 840 ? w * 0.42 : 60;
  }

  // ── My message (right side) ──
  Widget _myBubble(dynamic m, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: _bubbleSpacer(context)),
        Flexible(
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(m['content'],
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 14, height: 1.45)),
                  const SizedBox(height: 3),
                  Text(time,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: Colors.white.withOpacity(0.35))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Other's message (left side with avatar) ──
  Widget _otherBubble(
      dynamic m, String name, String time, bool showAvatar, Color sColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar or spacer
        if (showAvatar)
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: sColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: sColor),
              ),
            ),
          )
        else
          const SizedBox(width: 38),
        // Bubble
        Flexible(
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(showAvatar ? 4 : 16),
                  topRight: const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: Border.all(color: AppTheme.border.withOpacity(0.7)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(name,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sColor)),
                    ),
                  Text(m['content'],
                      style: GoogleFonts.inter(
                          color: AppTheme.textDark,
                          fontSize: 14,
                          height: 1.45)),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(time,
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppTheme.textLight)),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: _bubbleSpacer(context)),
      ],
    );
  }

  // ── Input ──
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: AppTheme.border.withOpacity(0.6))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F3),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _msgCtl,
                  enabled: _cd == 0,
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _cd > 0 ? 'Wait ${_cd}s...' : 'Message...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: _cd > 0
                          ? AppTheme.error.withOpacity(0.5)
                          : AppTheme.textLight,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _cd > 0 ? null : _send,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _cd > 0 ? AppTheme.borderStrong : AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _endedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        border:
            Border(top: BorderSide(color: AppTheme.border.withOpacity(0.6))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 14, color: AppTheme.textLight),
            const SizedBox(width: 6),
            Text('This class has ended',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}
