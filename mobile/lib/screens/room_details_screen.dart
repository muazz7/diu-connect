import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../core/demo_data.dart';
import '../widgets/premium_widgets.dart';
import 'dm_chat_screen.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String sectionId;
  final String title;
  final bool isActive;
  const RoomDetailsScreen(
      {super.key,
      required this.sectionId,
      required this.title,
      this.isActive = true});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _members = [];
  bool _loading = true;
  late bool _active;
  late AnimationController _anim;
  final _demo = DemoData();

  @override
  void initState() {
    super.initState();
    _active = widget.isActive;
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fetch();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      setState(() {
        _members = _demo.getMembers(widget.sectionId);
        _loading = false;
      });
      _anim.forward(from: 0);
      return;
    }
    try {
      final r = await http.get(
        Uri.parse('${auth.baseUrl}/sections/${widget.sectionId}/members'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (r.statusCode == 200) {
        setState(() {
          _members = jsonDecode(r.body);
          _loading = false;
        });
        _anim.forward(from: 0);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _remove(String uid) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      setState(() => _members.removeWhere((m) => m['id'] == uid));
      _snack('Removed', ok: true);
      return;
    }
    try {
      final r = await http.delete(
          Uri.parse(
              '${auth.baseUrl}/sections/${widget.sectionId}/members/$uid'),
          headers: {'Authorization': 'Bearer ${auth.token}'});
      if (r.statusCode == 200) {
        setState(() => _members.removeWhere((m) => m['id'] == uid));
        _snack('Removed', ok: true);
      } else {
        _snack('Failed');
      }
    } catch (_) {}
  }

  void _toggleModerator(String uid, String name, bool isMod) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      if (isMod) {
        _demo.removeModerator(widget.sectionId, uid);
        _snack('$name removed as moderator', ok: true);
      } else {
        _demo.setModerator(widget.sectionId, uid);
        _snack('$name is now a moderator', ok: true);
      }
      _fetch();
    }
  }

  Future<void> _end() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_demo.isDemoUser(auth.token)) {
      _demo.endClass(widget.sectionId);
      setState(() => _active = false);
      _snack('Class ended', ok: true);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    try {
      final r = await http.patch(
          Uri.parse('${auth.baseUrl}/sections/${widget.sectionId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${auth.token}'
          },
          body: jsonEncode({'isActive': false}));
      if (r.statusCode == 200) {
        setState(() => _active = false);
        _snack('Class ended', ok: true);
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        _snack('Failed');
      }
    } catch (_) {}
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _openDM(AuthProvider auth, String recipientId, String recipientName) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DMChatScreen(
          recipientId: recipientId,
          recipientName: recipientName,
        ),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, a, __, c) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: c),
      ),
    );
  }

  bool _canDM(AuthProvider auth, Map<String, dynamic> member) {
    final myId = auth.userId;
    final uid = member['id'];
    if (uid == myId) return false;
    final myRole = auth.role;
    final memberRole = member['role'] ?? 'student';

    if (myRole == 'TEACHER' || myRole == 'ADMIN') return true;
    // Student can DM teacher or moderator
    if (myRole == 'STUDENT') {
      return memberRole == 'teacher' || memberRole == 'moderator';
    }
    return false;
  }

  bool _canRemove(AuthProvider auth, Map<String, dynamic> member) {
    final myId = auth.userId;
    final uid = member['id'];
    if (uid == myId) return false;
    if (!_active) return false;
    final myRole = auth.role;
    final memberRole = member['role'] ?? 'student';

    // Teacher can remove anyone except themselves
    if (myRole == 'TEACHER' || myRole == 'ADMIN') return true;
    // Moderator can remove students only
    if (_demo.isModerator(widget.sectionId, myId ?? '')) {
      return memberRole == 'student';
    }
    return false;
  }

  void _confirmRemove(String uid, String name) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Container(
          width: 300,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Remove $name?',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                const SizedBox(height: 6),
                Text('They will be removed from this section.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textLight)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMid)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _remove(uid);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('Remove',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmEnd() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Container(
          width: 300,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.stop_circle_outlined,
                      color: AppTheme.error, size: 20),
                ),
                const SizedBox(height: 14),
                Text('End this class?',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                const SizedBox(height: 6),
                Text('It will move to "Previous" and can\'t be reopened.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textLight)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMid)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _end();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('End Class',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isTeacher = auth.role == 'TEACHER' || auth.role == 'ADMIN';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              // App bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.border.withOpacity(0.7)),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          size: 18, color: AppTheme.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text('Room Details',
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark)),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Course info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAF8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.auto_stories_rounded,
                                  color: AppTheme.accent, size: 20),
                            ),
                            const SizedBox(height: 10),
                            Text(widget.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    fontSize: 17, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _active
                                    ? AppTheme.success.withOpacity(0.08)
                                    : AppTheme.warm,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _active
                                          ? AppTheme.success
                                          : AppTheme.textLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _active ? 'Active' : 'Ended',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _active
                                          ? AppTheme.success
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Members header
                      Row(children: [
                        Text('Members',
                            style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppTheme.warm,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('${_members.length}',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMid)),
                        ),
                      ]),
                      const SizedBox(height: 10),

                      // Members list
                      Expanded(
                        child: _loading
                            ? const Center(child: PremiumSpinner())
                            : _members.isEmpty
                                ? const EmptyStateWidget(
                                    icon: Icons.group_off_rounded,
                                    title: 'No members')
                                : ListView.builder(
                                    itemCount: _members.length,
                                    itemBuilder: (_, i) {
                                      final m = _members[i];
                                      final delay = (i * 0.1).clamp(0.0, 0.6);
                                      final end = (delay + 0.4).clamp(0.0, 1.0);
                                      final curve = CurvedAnimation(
                                        parent: _anim,
                                        curve: Interval(delay, end,
                                            curve: Curves.easeOut),
                                      );
                                      return FadeTransition(
                                        opacity: curve,
                                        child: _memberRow(auth, m, isTeacher),
                                      );
                                    }),
                      ),

                      // End class — ONLY for teacher + active class
                      if (isTeacher && _active) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _confirmEnd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFFEF2F2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stop_circle_outlined,
                                    size: 16,
                                    color: AppTheme.error.withOpacity(0.8)),
                                const SizedBox(width: 6),
                                Text('End Class',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.error)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Ended status for inactive classes
                      if (!_active) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.warm,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 15, color: AppTheme.textLight),
                              const SizedBox(width: 6),
                              Text('This class has ended',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textLight)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberRow(AuthProvider auth, Map<String, dynamic> m, bool isTeacher) {
    final role = m['role'] ?? 'student';
    final isMod = role == 'moderator';
    final isTeacherMember = role == 'teacher';
    final canRemove = _canRemove(auth, m);
    final canDM = _canDM(auth, m);
    final canToggleMod =
        isTeacher && _active && !isTeacherMember && m['id'] != auth.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isTeacherMember
                ? AppTheme.accent.withOpacity(0.08)
                : isMod
                    ? const Color(0xFFFFF7ED)
                    : AppTheme.warm,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              m['name'][0].toUpperCase(),
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isTeacherMember
                      ? AppTheme.accent
                      : isMod
                          ? const Color(0xFFEA580C)
                          : AppTheme.textMid),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + role badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(m['name'],
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  if (isTeacherMember) ...[
                    const SizedBox(width: 6),
                    _badge('Teacher', AppTheme.accent),
                  ],
                  if (isMod) ...[
                    const SizedBox(width: 6),
                    _badge('Mod', const Color(0xFFEA580C)),
                  ],
                ],
              ),
              Text(m['email'],
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textLight)),
            ],
          ),
        ),
        // DM button
        if (canDM)
          IconButton(
            icon: Icon(Icons.chat_bubble_outline_rounded,
                size: 16, color: AppTheme.accent.withOpacity(0.7)),
            onPressed: () => _openDM(auth, m['id'], m['name']),
            tooltip: 'Direct message',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        // Moderator toggle (teacher only)
        if (canToggleMod)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                size: 18, color: AppTheme.textLight),
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'mod') {
                _toggleModerator(m['id'], m['name'], isMod);
              } else if (v == 'remove') {
                _confirmRemove(m['id'], m['name']);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'mod',
                child: Row(
                  children: [
                    Icon(
                        isMod
                            ? Icons.remove_moderator_outlined
                            : Icons.shield_outlined,
                        size: 16,
                        color: isMod ? AppTheme.error : AppTheme.accent),
                    const SizedBox(width: 8),
                    Text(isMod ? 'Remove Moderator' : 'Make Moderator',
                        style: GoogleFonts.inter(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_outlined,
                        size: 16, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Text('Remove',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
        // Remove button for moderators (not teachers)
        if (!isTeacher && canRemove)
          IconButton(
            icon: Icon(Icons.person_remove_outlined,
                size: 18, color: AppTheme.error.withOpacity(0.6)),
            onPressed: () => _confirmRemove(m['id'], m['name']),
          ),
      ]),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
