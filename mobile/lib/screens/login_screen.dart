import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _idCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  bool _isLogin = true;
  String _role = 'STUDENT';
  bool _hidePass = true;

  late AnimationController _fadeAnim;
  late AnimationController _roleAnim;

  @override
  void initState() {
    super.initState();
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _roleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..forward();
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    _roleAnim.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _idCtl.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  void _toggle() {
    _fadeAnim.reverse().then((_) {
      setState(() => _isLogin = !_isLogin);
      _fadeAnim.forward();
    });
  }

  void _switchRole(String r) {
    if (r == _role) return;
    _roleAnim.reverse(from: 0.6).then((_) {
      setState(() => _role = r);
      _roleAnim.forward();
    });
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

  Future<void> _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_isLogin) {
      if (_emailCtl.text.isEmpty || _passCtl.text.isEmpty) {
        return _snack('Please fill in all fields');
      }
      final r = await auth.login(_emailCtl.text.trim(), _passCtl.text);
      if (r['success'] && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (mounted) {
        _snack(r['error'] ?? 'Login failed');
      }
    } else {
      if (_nameCtl.text.isEmpty ||
          _emailCtl.text.isEmpty ||
          _passCtl.text.isEmpty) {
        return _snack('Please fill in all fields');
      }
      if (_role == 'STUDENT' && _idCtl.text.isEmpty) {
        return _snack('Student ID is required');
      }
      final r = await auth.register(
        _nameCtl.text.trim(),
        _emailCtl.text.trim(),
        _passCtl.text,
        _role,
        studentId: _role == 'STUDENT' ? _idCtl.text.trim() : null,
      );
      if (r['success'] && mounted) {
        _snack('Account created! Please sign in.', ok: true);
        _toggle();
      } else if (mounted) {
        _snack(r['error'] ?? 'Registration failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeAnim,
                curve: Curves.easeOut,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _branding(),
                      const SizedBox(height: 32),
                      _form(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _branding() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.accentSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.school_rounded,
              size: 32, color: AppTheme.accent),
        ),
        const SizedBox(height: 16),
        Text(
          'DIU Connect',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'University communication platform',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppTheme.textLight, height: 1.4),
        ),
      ],
    );
  }

  Widget _form() {
    final auth = Provider.of<AuthProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with smooth crossfade
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Column(
              key: ValueKey(_isLogin),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLogin ? 'Welcome back' : 'Create account',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isLogin ? 'Sign in to continue' : 'Join your university',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Role selector
          _roleSelector(),
          const SizedBox(height: 16),

          // Animated extra fields
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                if (!_isLogin) ...[
                  _field(_nameCtl, 'Full Name', Icons.person_outlined),
                  const SizedBox(height: 12),
                ],
                if (!_isLogin && _role == 'STUDENT') ...[
                  _field(_idCtl, 'Student ID (e.g. 242-35-123)',
                      Icons.badge_outlined),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // Crossfade for role-dependent fields
          FadeTransition(
            opacity: CurvedAnimation(parent: _roleAnim, curve: Curves.easeOut),
            child: Column(
              children: [
                _field(_emailCtl, 'Email', Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field(_passCtl, 'Password', Icons.lock_outlined,
                    obscure: _hidePass,
                    suffix: IconButton(
                      icon: Icon(
                        _hidePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textLight,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _hidePass = !_hidePass),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(_isLogin ? 'Sign In' : 'Create Account'),
            ),
          ),

          const SizedBox(height: 14),

          TextButton(
            onPressed: _toggle,
            child: Text.rich(
              TextSpan(
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight),
                children: [
                  TextSpan(
                      text: _isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? '),
                  TextSpan(
                    text: _isLogin ? 'Sign Up' : 'Sign In',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctl, String label, IconData icon,
      {TextInputType? type, bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: ctl,
      keyboardType: type,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textLight, size: 20),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _roleSelector() {
    final roles = _isLogin
        ? [
            ('STUDENT', 'Student', Icons.school_outlined),
            ('TEACHER', 'Teacher', Icons.person_outlined),
            ('ADMIN', 'Admin', Icons.shield_outlined),
          ]
        : [
            ('STUDENT', 'Student', Icons.school_outlined),
            ('TEACHER', 'Teacher', Icons.person_outlined),
          ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warm,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = roles.length;
          final pillWidth = (constraints.maxWidth - 8) / count;
          final idx = roles.indexWhere((r) => r.$1 == _role);
          final safeIdx = idx < 0 ? 0 : idx;

          return Stack(
            children: [
              // Sliding indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: safeIdx * pillWidth + 4,
                top: 0,
                bottom: 0,
                width: pillWidth - 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Buttons
              Row(
                children: roles.map((r) {
                  final sel = _role == r.$1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _switchRole(r.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(fontSize: 0),
                              child: Icon(r.$3,
                                  size: 16,
                                  color: sel
                                      ? AppTheme.accent
                                      : AppTheme.textLight),
                            ),
                            const SizedBox(width: 5),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel
                                    ? AppTheme.textDark
                                    : AppTheme.textLight,
                              ),
                              child: Text(r.$2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
