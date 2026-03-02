import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

class CourseCard extends StatelessWidget {
  final dynamic course;
  final VoidCallback onTap;
  final bool isGrid;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isGrid ? _grid() : _list(),
        ),
      ),
    );
  }

  Widget _list() {
    return Row(
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course['name'],
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _tag(course['code']),
                  const SizedBox(width: 6),
                  Text(
                    course['teacher']?['name'] ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            size: 20, color: AppTheme.textLight),
      ],
    );
  }

  Widget _grid() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_stories_rounded,
              color: AppTheme.accent, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          course['name'],
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        _tag(course['code']),
        const Spacer(),
        Text(
          course['teacher']?['name'] ?? '',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.warm,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMid)),
    );
  }
}
