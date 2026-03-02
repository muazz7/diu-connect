import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    String roleLabel;
    switch (auth.role) {
      case 'STUDENT':
        roleLabel = 'Student';
        break;
      case 'TEACHER':
        roleLabel = 'Faculty';
        break;
      case 'ADMIN':
        roleLabel = 'Administrator';
        break;
      default:
        roleLabel = auth.role ?? '';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile',
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 20),

                  // ── Avatar + Name ──
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1C1917),
                                Color(0xFF44403C),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              (auth.userName ?? 'U')[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          auth.userName ?? 'User',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Account section ──
                  _sectionLabel('ACCOUNT'),
                  const SizedBox(height: 8),
                  _infoCard([
                    _infoRow(
                      Icons.person_outline_rounded,
                      'Name',
                      auth.userName ?? '—',
                    ),
                    _divider(),
                    if (auth.studentId != null &&
                        auth.studentId!.isNotEmpty) ...[
                      _infoRow(
                        Icons.badge_outlined,
                        'Student ID',
                        auth.studentId!,
                      ),
                      _divider(),
                    ],
                    _infoRow(
                      Icons.email_outlined,
                      'Email',
                      auth.email ?? '—',
                    ),
                    _divider(),
                    _infoRow(
                      Icons.badge_outlined,
                      'Role',
                      roleLabel,
                    ),
                    _divider(),
                    _infoRow(
                      Icons.school_outlined,
                      'Institution',
                      'Daffodil International University',
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── App section ──
                  _sectionLabel('APP'),
                  const SizedBox(height: 8),
                  _infoCard([
                    _infoRow(
                      Icons.info_outline_rounded,
                      'Version',
                      '1.0.0',
                    ),
                    _divider(),
                    _infoRow(
                      Icons.palette_outlined,
                      'Theme',
                      'Light',
                    ),
                  ]),

                  const SizedBox(height: 36),

                  // ── Sign out ──
                  _signOutButton(auth),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textLight,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: AppTheme.textMid),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppTheme.textMid,
                  fontWeight: FontWeight.w400)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Container(height: 1, color: AppTheme.border),
    );
  }

  Widget _signOutButton(AuthProvider auth) {
    return GestureDetector(
      onTap: () => _confirmSignOut(auth),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFECACA)),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFFEF2F2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded,
                size: 18, color: AppTheme.error.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(
              'Sign out',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(AuthProvider auth) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.0)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Container(
            width: 320,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: AppTheme.error, size: 22),
                  ),
                  const SizedBox(height: 16),
                  Text('Sign out?',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Text(
                    'You can sign back in anytime.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text('Cancel',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMid)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(ctx);
                            await auth.logout();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/', (r) => false);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text('Sign out',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
