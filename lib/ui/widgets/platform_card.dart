import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class PlatformCard extends StatefulWidget {
  final String platform;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final bool connected;
  final bool readOnly; // ✅ NEW
  final Function(bool value)? onToggle;

  const PlatformCard({
    super.key,
    required this.platform,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.connected,
    this.readOnly = false, // ✅ DEFAULT
    this.onToggle,
  });

  @override
  State<PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends State<PlatformCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────────────── ICON ─────────────────
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.95),
                      widget.color.withOpacity(0.65),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),

              const SizedBox(width: 16),

              // ───────────────── TEXT ─────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.textMedium,
                      ),
                    ),
                    if (widget.readOnly) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Managed from web dashboard',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ───────────────── SWITCH ─────────────────
              Switch(
                value: widget.connected,
                activeColor: widget.color,
                onChanged: widget.readOnly
                    ? null // 🔒 DISABLED
                    : (v) {
                        widget.onToggle?.call(v);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${widget.title} ${v ? 'connected' : 'disconnected'}",
                            ),
                            duration:
                                const Duration(milliseconds: 900),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
