import 'package:flutter/material.dart';

/// Quiet stepped frames shared by the HUD and sheets; no image decoding needed.
class AtlasPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool accented;
  const AtlasPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
    this.color = const Color(0xff123b43),
    this.accented = false,
  });
  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _AtlasFrame(accented),
    child: ColoredBox(
      color: color,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class _AtlasFrame extends CustomPainter {
  final bool accented;
  const _AtlasFrame(this.accented);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..isAntiAlias = false;
    final border = Path()
      ..moveTo(5, 1)
      ..lineTo(size.width - 5, 1)
      ..lineTo(size.width - 1, 5)
      ..lineTo(size.width - 1, size.height - 5)
      ..lineTo(size.width - 5, size.height - 1)
      ..lineTo(5, size.height - 1)
      ..lineTo(1, size.height - 5)
      ..lineTo(1, 5)
      ..close();
    canvas.drawPath(
      border,
      paint
        ..color = accented ? const Color(0xffc1a871) : const Color(0xff628a83)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      const Offset(6, 3),
      Offset(size.width - 6, 3),
      paint..color = const Color(0xff315d60),
    );
    for (final x in [3.0, size.width - 5]) {
      for (final y in [3.0, size.height - 5]) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, 2, 2),
          paint
            ..style = PaintingStyle.fill
            ..color = accented
                ? const Color(0xffedc577)
                : const Color(0xff94b0a0),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AtlasFrame old) => old.accented != accented;
}

class AtlasViewLabel extends StatelessWidget {
  final String mode;
  final VoidCallback? onTap;
  const AtlasViewLabel(this.mode, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Cambiar escala',
    child: InkWell(
      onTap: onTap,
      child: AtlasPanel(
        accented: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Text(
          mode == 'Mundo' ? 'PLANETA' : mode.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'serif',
            color: Color(0xfff0ddb0),
            fontSize: 14,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
