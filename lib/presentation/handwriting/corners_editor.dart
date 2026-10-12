import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/handwriting/straightening.dart';

/// A photo with four corners to drag onto the corners of a board or page
/// (T6a.4, DD-021, SPEC Q45). The part outside the corners is dimmed; the
/// outline shows in the error colour when the corners cannot be read
/// ([usable] false). A corner is grabbed within [grabRadius] of it, and
/// keeps where it was grabbed, so it does not jump to the finger.
class CornersEditor extends StatefulWidget {
  const CornersEditor({
    super.key,
    required this.image,
    required this.corners,
    required this.usable,
    required this.onChanged,
  });

  final ui.Image image;
  final Corners corners;
  final bool usable;
  final ValueChanged<Corners> onChanged;

  /// Room around the photo, so a corner on its edge can still be grabbed.
  static const margin = 24.0;

  static const grabRadius = 40.0;

  @override
  State<CornersEditor> createState() => _CornersEditorState();
}

class _CornersEditorState extends State<CornersEditor> {
  Corner? _active;
  Offset _grab = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final shown = _shownRect(constraints.biggest);
        Offset onScreen(Corner c) {
          final p = widget.corners[c];
          return shown.topLeft + Offset(p.x * shown.width, p.y * shown.height);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            Corner? nearest;
            var best = CornersEditor.grabRadius;
            for (final c in Corner.values) {
              final d = (onScreen(c) - details.localPosition).distance;
              if (d <= best) {
                best = d;
                nearest = c;
              }
            }
            setState(() {
              _active = nearest;
              if (nearest != null) {
                _grab = onScreen(nearest) - details.localPosition;
              }
            });
          },
          onPanUpdate: (details) {
            final active = _active;
            if (active == null || shown.isEmpty) return;
            final at = details.localPosition + _grab - shown.topLeft;
            widget.onChanged(
              widget.corners.moved(
                active,
                CornerPoint(at.dx / shown.width, at.dy / shown.height),
              ),
            );
          },
          onPanEnd: (_) => setState(() => _active = null),
          onPanCancel: () => setState(() => _active = null),
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: shown,
                child: RawImage(image: widget.image, fit: BoxFit.fill),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _CornersPainter(
                    points: [for (final c in Corner.values) onScreen(c)],
                    photo: shown,
                    active: _active?.index,
                    line: widget.usable ? scheme.primary : scheme.error,
                    handle: widget.usable ? scheme.primary : scheme.error,
                    handleBorder: scheme.onPrimary,
                    dim: scheme.scrim.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Where the photo shows in [size]: as large as fits within the margin,
  /// centred, its shape kept.
  Rect _shownRect(Size size) {
    const m = CornersEditor.margin;
    final room = Size(
      math.max(0, size.width - 2 * m),
      math.max(0, size.height - 2 * m),
    );
    final scale = math.min(
      room.width / widget.image.width,
      room.height / widget.image.height,
    );
    final shown = Size(widget.image.width * scale, widget.image.height * scale);
    return Offset(
          (size.width - shown.width) / 2,
          (size.height - shown.height) / 2,
        ) &
        shown;
  }
}

class _CornersPainter extends CustomPainter {
  _CornersPainter({
    required this.points,
    required this.photo,
    required this.active,
    required this.line,
    required this.handle,
    required this.handleBorder,
    required this.dim,
  });

  /// The corners on screen, clockwise from the top left.
  final List<Offset> points;
  final Rect photo;
  final int? active;
  final Color line;
  final Color handle;
  final Color handleBorder;

  /// Over the part of the photo that will not be read.
  final Color dim;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = Path()..addPolygon(points, true);
    // The photo outside the corners, dimmed: what will not be read.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(photo)
        ..addPolygon(points, true),
      Paint()..color = dim,
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final (i, p) in points.indexed) {
      final radius = i == active ? 14.0 : 10.0;
      canvas
        ..drawCircle(p, radius + 2, Paint()..color = handleBorder)
        ..drawCircle(p, radius, Paint()..color = handle);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter old) =>
      old.active != active ||
      old.line != line ||
      old.photo != photo ||
      !_samePoints(old.points, points);

  static bool _samePoints(List<Offset> a, List<Offset> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
