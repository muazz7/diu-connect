import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/demo_data.dart';

class DMChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final bool embedded;
  final VoidCallback? onBack;
  const DMChatScreen(
      {super.key,
      required this.recipientId,
      required this.recipientName,
      this.embedded = false,
      this.onBack});

  @override
  State<DMChatScreen> createState() => _DMChatScreenState();
}

class _DMChatScreenState extends State<DMChatScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtl = TextEditingController();
  final _scroll = ScrollController();
  List<dynamic> _msgs = [];
  Timer? _poll;
  final _demo = DemoData();
  bool _first = true;
  late AnimationController _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350))
      ..forward();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _msgCtl.dispose();
    _scroll.dispose();
    _entryAnim.dispose();
    super.dispose();
  }

  void _load() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      final data = _demo.getDMMessages(auth.userId ?? '', widget.recipientId);
      final prev = _msgs.length;
      setState(() => _msgs = data);
      if (_first || data.length > prev) {
        _first = false;
        _bottom();
      }
    }
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

  void _send() {
    if (_msgCtl.text.trim().isEmpty) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txt = _msgCtl.text.trim();
    _msgCtl.clear();
    if (_demo.isDemoUser(auth.token)) {
      _demo.sendDM(
          auth.userId ?? '', auth.userName ?? '', widget.recipientId, txt);
      _load();
    }
  }

  String _fmtTime(String s) {
    try {
      return DateFormat.jm().format(DateTime.parse(s).toLocal());
    } catch (_) {
      return '';
    }
  }

  double _bubbleSpacer(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 840 ? w * 0.42 : 60;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final body = Column(
      children: [
        _topBar(),
        Expanded(child: _messageList(auth)),
        _inputBar(),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: body),
    );
  }

  Widget _topBar() {
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
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: 18, color: AppTheme.textDark),
              onPressed: () {
                if (widget.embedded && widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  widget.recipientName[0].toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.recipientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  Text('Direct message',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageList(AuthProvider auth) {
    if (_msgs.isEmpty) {
      return Container(
        color: const Color(0xFFFAFAF8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    size: 24, color: AppTheme.textLight),
              ),
              const SizedBox(height: 12),
              Text('No messages yet',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMid)),
              const SizedBox(height: 4),
              Text('Start a conversation with ${widget.recipientName}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textLight)),
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
        itemBuilder: (_, i) {
          final m = _msgs[i];
          final me = m['senderId'] ==
              Provider.of<AuthProvider>(context, listen: false).userId;
          final time = _fmtTime(m['createdAt'] ?? '');
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: me ? _myBubble(m, time) : _otherBubble(m, time),
          );
        },
      ),
    );
  }

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

  Widget _otherBubble(dynamic m, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: AppTheme.border.withOpacity(0.7)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textLight),
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
              onTap: _send,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
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
}
