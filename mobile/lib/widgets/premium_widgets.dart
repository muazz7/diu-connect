import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

/// Wraps content in a centered card on wide screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  const ResponsiveContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth > 600) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.shadowLg,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: child,
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}

/// Clean card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadow,
      ),
      child: child,
    );
  }
}

class PremiumSpinner extends StatelessWidget {
  final double size;
  const PremiumSpinner({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyStateWidget(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.warm,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: AppTheme.textLight),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMid)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight)),
          ],
        ],
      ),
    );
  }
}

/// White AppBar bottom border — Apple-style
class AppBarBottomBorder extends StatelessWidget
    implements PreferredSizeWidget {
  final PreferredSizeWidget? child;
  const AppBarBottomBorder({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: child,
    );
  }

  @override
  Size get preferredSize => child?.preferredSize ?? const Size.fromHeight(0);
}
