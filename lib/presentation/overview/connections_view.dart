import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../../domain/connections/connection_layout.dart';
import '../../domain/people/person.dart';
import '../../l10n/app_localizations.dart';
import '../home/item_panes.dart';
import '../theme/design_tokens.dart';
import '../tokens/token_editor.dart';
import 'connections_look.dart';
import 'connections_providers.dart';
import 'connections_sheets.dart';

/// The zoomable graph, where the keys of Windows work: for tests.
const connectionsGraphKey = ValueKey('connectionsGraph'); // l10n-ignore: key

/// Connections, the fourth segment of Insights (T10.14, REQ-059, DD-018
/// point 15): a local graph around one focus, 1 or 2 steps deep, that can
/// be zoomed.
class ConnectionsView extends ConsumerStatefulWidget {
  const ConnectionsView({super.key});

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView> {
  void _focusOn(NodeRef node) => ref
      .read(connectionsProvider.notifier)
      .focusOn(node, from: ref.read(connectionsFocusProvider));

  Future<void> _change() async {
    final node = await chooseFocus(context);
    if (node != null && mounted) _focusOn(node);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final focus = ref.watch(connectionsFocusProvider);
    final data = ref.watch(connectionDataProvider);
    final twoSteps = ref.watch(connectionsProvider.select((s) => s.twoSteps));
    // On Windows the right pane shows the focus when it is an item (DD-018
    // point 15 (e)); a person or project focus the shell shows there.
    ref.listen(connectionsFocusProvider, (_, next) {
      if (next?.kind != NodeKind.item) return;
      final panes = ItemPanes.find(context);
      if (panes != null && panes.detailPane) panes.select(next!.id);
    });

    if (data == null) return const Center(child: CircularProgressIndicator());
    if (focus == null || !data.contains(focus)) {
      return _Empty(onChoose: _change);
    }
    final looks = nodeLooksOf(ref, data, l10n);
    final graph = data.graphOf(focus, twoSteps: twoSteps);
    final desktop = isDesktop(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    // Back to the previous focus: the shell's back on a phone, Escape and
    // Alt+Left in the graph on Windows.
    return Padding(
      // On a phone the Capture button floats over the bottom right; the
      // card stops above it.
      padding: EdgeInsets.fromLTRB(12, 8, 12, desktop ? 4 : 76),
      child: Card(
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.connectionsFocusKind(focus.kind.name),
                          style: muted,
                        ),
                        Text(
                          looks.of(focus).title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _change,
                    child: Text(l10n.connectionsChange),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.connectionsOneStep),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.connectionsTwoSteps),
                  ),
                ],
                selected: {twoSteps},
                onSelectionChanged: (s) => ref
                    .read(connectionsProvider.notifier)
                    .setTwoSteps(s.single),
              ),
              Expanded(
                child: _Graph(
                  graph: graph,
                  looks: looks,
                  onFocus: _focusOn,
                  onPreview: (node) => showNodePreview(
                    context,
                    ref,
                    node,
                    isFocus: node == focus,
                  ),
                  onMore: () => showAllConnections(context, ref, graph),
                  onBack: () => ref.read(connectionsProvider.notifier).back(),
                ),
              ),
              Wrap(
                spacing: 16,
                children: [
                  _LegendLine(
                    dashed: false,
                    label: l10n.connectionsLegendDirect,
                  ),
                  if (twoSteps)
                    _LegendLine(
                      dashed: true,
                      label: l10n.connectionsLegendThrough,
                    ),
                ],
              ),
              Text(
                desktop ? l10n.connectionsHintDesktop : l10n.connectionsHint,
                style: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// No focus yet: the question and *Kies een item* (DD-018 point 15).
class _Empty extends StatelessWidget {
  const _Empty({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.connectionsEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.connectionsEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onChoose,
              child: Text(l10n.connectionsChoose),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({required this.dashed, required this.label});

  final bool dashed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 10),
          painter: _LegendPainter(dashed: dashed),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LegendPainter extends CustomPainter {
  const _LegendPainter({required this.dashed});

  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dashed ? connectionFarLineColor : connectionLineColor
      ..strokeWidth = dashed ? 1.6 : 2;
    final y = size.height / 2;
    if (dashed) {
      _dashed(canvas, Offset(0, y), Offset(size.width, y), paint);
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LegendPainter old) => old.dashed != dashed;
}

void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
  const dash = 4.0, gap = 4.0;
  final length = (b - a).distance;
  if (length == 0) return;
  final step = (b - a) / length;
  for (var d = 0.0; d < length; d += dash + gap) {
    canvas.drawLine(a + step * d, a + step * math.min(d + dash, length), paint);
  }
}

/// One drawn node: where it is and what it stands for. [node] is null for
/// "+n meer".
class _Drawn {
  const _Drawn({
    required this.node,
    required this.place,
    required this.far,
    this.ties = const {},
    this.parent,
    this.behind = 0,
  });

  final NodeRef? node;
  final Placement place;
  final bool far;
  final Set<Tie> ties;
  final NodeRef? parent;

  /// The second-step nodes behind it that are not drawn: its "+n".
  final int behind;

  Offset get centre => Offset(place.x, place.y);
}

/// The graph itself: laid out for the room it gets, zoomable, with the
/// keys of Windows (DD-018 point 15).
class _Graph extends StatefulWidget {
  const _Graph({
    required this.graph,
    required this.looks,
    required this.onFocus,
    required this.onPreview,
    required this.onMore,
    required this.onBack,
  });

  final ConnectionGraph graph;
  final NodeLooks looks;
  final ValueChanged<NodeRef> onFocus;
  final ValueChanged<NodeRef> onPreview;
  final VoidCallback onMore;
  final VoidCallback onBack;

  @override
  State<_Graph> createState() => _GraphState();
}

class _GraphState extends State<_Graph> {
  final _zoom = TransformationController();
  final _keys = FocusNode();

  /// What the arrows select (Windows): null for the focus, a [NodeRef],
  /// or [_moreNode] for "+n meer".
  Object? _selected;

  static const _moreNode = #more;
  var _keysFocused = false;

  /// What the zoom was last set for: a new graph or room starts again.
  String? _zoomedFor;
  Size _view = Size.zero;
  ConnectionLayout? _layout;

  @override
  void dispose() {
    _zoom.dispose();
    _keys.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_Graph old) {
    super.didUpdateWidget(old);
    if (old.graph.focus != widget.graph.focus) _selected = null;
  }

  /// The scale at which the whole canvas fits the room, at most 1.
  double get _fitScale {
    final layout = _layout;
    if (layout == null || _view.isEmpty) return 1;
    return math.min(
      1,
      math.min(_view.width / _canvasWidth, _view.height / layout.height),
    );
  }

  double _canvasWidth = 0;

  /// Shows the whole graph.
  void _fit() {
    final layout = _layout;
    if (layout == null) return;
    final s = _fitScale;
    final dx = (_view.width - _canvasWidth * s) / 2;
    final dy = (_view.height - layout.height * s) / 2;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  /// The start (decision of the PO, 04-10-2026): the whole graph when it
  /// fits at 80 % or more, otherwise 100 % with the focus in the middle.
  void _start() {
    final layout = _layout;
    if (layout == null) return;
    if (_fitScale >= 0.8) {
      _fit();
      return;
    }
    final focus = layout.focus;
    final cx = focus.left + focus.width / 2;
    final cy = focus.top + focus.height / 2;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(_view.width / 2 - cx, _view.height / 2 - cy, 0, 1);
  }

  /// Moves the graph by [delta], no further than the margin the viewer
  /// allows, so it never leaves the room altogether.
  void _panBy(Offset delta) {
    final layout = _layout;
    if (layout == null) return;
    const margin = 160.0;
    final m = _zoom.value;
    final s = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final minX = _view.width - (_canvasWidth + margin) * s;
    final minY = _view.height - (layout.height + margin) * s;
    final x = (t.x + delta.dx)
        .clamp(math.min(minX, margin * s), margin * s)
        .toDouble();
    final y = (t.y + delta.dy)
        .clamp(math.min(minY, margin * s), margin * s)
        .toDouble();
    _zoom.value = m.clone()..setTranslationRaw(x, y, t.z);
  }

  void _scaleBy(double factor) {
    final centre = Offset(_view.width / 2, _view.height / 2);
    final scale = _zoom.value.getMaxScaleOnAxis() * factor;
    if (scale < 0.3 || scale > 3) return;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(centre.dx, centre.dy, 0, 1)
      ..scaleByDouble(factor, factor, 1, 1)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1)
      ..multiply(_zoom.value);
  }

  /// The drawn node nearest to the selected one in [direction] (Windows).
  void _move(List<_Drawn> drawn, Offset focusCentre, AxisDirection direction) {
    Object key(_Drawn d) => d.node ?? _moreNode;
    final from = _selected == null
        ? focusCentre
        : drawn
                  .where((d) => key(d) == _selected)
                  .map((d) => d.centre)
                  .firstOrNull ??
              focusCentre;
    final points = <(Object?, Offset)>[
      if (_selected != null) (null, focusCentre),
      for (final d in drawn)
        if (key(d) != _selected) (key(d), d.centre),
    ];
    (Object?, Offset)? best;
    var bestScore = double.infinity;
    for (final p in points) {
      final delta = p.$2 - from;
      final (along, across) = switch (direction) {
        AxisDirection.right => (delta.dx, delta.dy.abs()),
        AxisDirection.left => (-delta.dx, delta.dy.abs()),
        AxisDirection.down => (delta.dy, delta.dx.abs()),
        AxisDirection.up => (-delta.dy, delta.dx.abs()),
      };
      if (along <= 1) continue;
      final score = along + 2 * across;
      if (score < bestScore) {
        bestScore = score;
        best = p;
      }
    }
    if (best != null) setState(() => _selected = best!.$1);
  }

  KeyEventResult _onKey(
    KeyEvent event,
    List<_Drawn> drawn,
    Offset focusCentre,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed) {
      if (key == LogicalKeyboardKey.equal ||
          key == LogicalKeyboardKey.add ||
          key == LogicalKeyboardKey.numpadAdd) {
        _scaleBy(1.25);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.minus ||
          key == LogicalKeyboardKey.numpadSubtract) {
        _scaleBy(0.8);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit0 ||
          key == LogicalKeyboardKey.numpad0) {
        _fit();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (keyboard.isAltPressed && key == LogicalKeyboardKey.arrowLeft) {
      widget.onBack();
      return KeyEventResult.handled;
    }
    final direction = switch (key) {
      LogicalKeyboardKey.arrowRight => AxisDirection.right,
      LogicalKeyboardKey.arrowLeft => AxisDirection.left,
      LogicalKeyboardKey.arrowDown => AxisDirection.down,
      LogicalKeyboardKey.arrowUp => AxisDirection.up,
      _ => null,
    };
    if (direction != null) {
      _move(drawn, focusCentre, direction);
      return KeyEventResult.handled;
    }
    final selected = _selected;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      // A node becomes the focus; "+n meer" opens its list; the focus itself
      // is the focus already, so Enter shows its preview.
      switch (selected) {
        case final NodeRef node:
          widget.onFocus(node);
        case _moreNode:
          widget.onMore();
        default:
          widget.onPreview(widget.graph.focus);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      switch (selected) {
        case final NodeRef node:
          widget.onPreview(node);
        case _moreNode:
          widget.onMore();
        default:
          widget.onPreview(widget.graph.focus);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      widget.onBack();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final graph = widget.graph;
    final looks = widget.looks;
    final desktop = isDesktop(context);
    // Sizes grow with the text size, so labels keep their room.
    final textScale =
        MediaQuery.textScalerOf(context).scale(12).clamp(12.0, 18.0) / 12;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final narrow = width < 400;
        final metrics = LayoutMetrics(
          width: width,
          height: constraints.maxHeight,
          labelWidth: (narrow ? 84 : 100) * textScale,
          focusWidth: (narrow ? 120 : 150) * textScale,
          focusHeight: 40 * textScale,
          captionHeight: 12 * textScale,
          lineHeight: 15 * textScale,
          moreWidth: 64 * textScale,
        );
        final shown = graph.shownDirect;
        final more = graph.hiddenDirect > 0;
        final seconds = [
          for (final d in shown) graph.secondOf(d.node).length,
          if (more) 0,
        ];
        final layout = layoutConnections(
          seconds,
          metrics,
          twoSteps: graph.twoSteps,
          more: more,
        );
        _layout = layout;
        _canvasWidth = width;
        _view = Size(constraints.maxWidth, constraints.maxHeight);
        final drawn = <_Drawn>[
          for (final (i, d) in shown.indexed)
            _Drawn(
              node: d.node,
              place: layout.direct[i],
              far: false,
              ties: d.ties,
              behind: graph.hiddenBehind(d.node),
            ),
          if (more) _Drawn(node: null, place: layout.direct.last, far: false),
          for (final (i, d) in shown.indexed)
            for (final (j, s) in graph.secondOf(d.node).indexed)
              _Drawn(
                node: s.node,
                place: layout.second[i][j],
                far: true,
                ties: s.ties,
                parent: d.node,
              ),
        ];
        final centres = {
          for (final d in drawn)
            if (d.node != null) d.node!: d.centre,
        };
        final focusBox = layout.focus;
        final focusCentre = Offset(
          focusBox.left + focusBox.width / 2,
          focusBox.top + focusBox.height / 2,
        );
        final lines = <(Offset, Offset, bool)>[
          for (final d in drawn)
            if (!d.far) (focusCentre, d.centre, false),
          for (final s in graph.second)
            for (final via in s.via)
              if (centres[via] != null && centres[s.node] != null)
                (centres[via]!, centres[s.node]!, true),
        ];

        // A new focus, depth or room: the zoom starts again.
        final key =
            '${graph.focus}|${graph.twoSteps}|${layout.height}|${_view.width}|${_view.height}'; // l10n-ignore: cache key
        if (key != _zoomedFor) {
          _zoomedFor = key;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _start();
          });
        }

        final throughCount = graph.second.length;
        final focusLook = looks.of(graph.focus);
        var order = 0;
        Widget sorted(Widget child) => Semantics(
          sortKey: OrdinalSortKey((order++).toDouble()),
          child: child,
        );

        final canvas = SizedBox(
          width: width,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(painter: _LinesPainter(lines)),
                ),
              ),
              Positioned(
                left: focusBox.left,
                top: focusBox.top,
                width: focusBox.width,
                height: focusBox.height,
                child: sorted(
                  Semantics(
                    button: true,
                    excludeSemantics: true,
                    label: l10n.connectionsFocusSemantics(
                      focusLook.kind,
                      focusLook.title,
                      graph.direct.length,
                      throughCount,
                    ),
                    onTap: () => widget.onPreview(graph.focus),
                    child: _FocusPill(
                      title: focusLook.title,
                      selected: _keysFocused && _selected == null,
                      onTap: () => widget.onPreview(graph.focus),
                    ),
                  ),
                ),
              ),
              for (final d in drawn)
                Positioned(
                  left: d.place.bounds.left,
                  top: d.place.bounds.top,
                  width: d.place.bounds.width,
                  height: d.place.bounds.height,
                  child: sorted(
                    d.node == null
                        ? Semantics(
                            button: true,
                            excludeSemantics: true,
                            label: l10n.connectionsMoreSemantics(
                              graph.hiddenDirect,
                            ),
                            onTap: widget.onMore,
                            child: _MoreNode(
                              count: graph.hiddenDirect,
                              selected: _keysFocused && _selected == _moreNode,
                              onTap: widget.onMore,
                            ),
                          )
                        : _NodeTile(
                            drawn: d,
                            look: looks.of(d.node!),
                            semantics: d.far
                                ? l10n.connectionsThroughSemantics(
                                    looks.of(d.parent!).title,
                                    looks.of(d.node!).kind,
                                    looks.of(d.node!).title,
                                  )
                                : [
                                    l10n.connectionsDirectSemantics(
                                      looks.of(d.node!).kind,
                                      looks.of(d.node!).title,
                                      [
                                        if (looks.of(d.node!).urgency !=
                                            Urgency.none)
                                          looks.of(d.node!).caption,
                                        ...looks.reasons(
                                          graph.focus,
                                          d.node!,
                                          d.ties,
                                        ),
                                      ].reduce(l10n.connectionsList),
                                    ),
                                    if (d.behind > 0)
                                      l10n.connectionsBehindSemantics(
                                        d.behind,
                                        looks.of(d.node!).title,
                                      ),
                                  ].reduce(l10n.connectionsList),
                            previewLabel: l10n.connectionsPreviewAction,
                            selected: _keysFocused && _selected == d.node,
                            desktop: desktop,
                            preview: desktop
                                ? _HoverCard(look: looks.of(d.node!))
                                : null,
                            onTap: () {
                              // A click gives the keys to the graph.
                              if (desktop) _keys.requestFocus();
                              widget.onFocus(d.node!);
                            },
                            onLongPress: () => widget.onPreview(d.node!),
                            textScale: textScale,
                          ),
                  ),
                ),
              if (graph.direct.isEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  top: focusBox.bottom + 12,
                  child: Text(
                    l10n.connectionsNothing,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );

        Widget viewer = InteractiveViewer(
          key: connectionsGraphKey,
          transformationController: _zoom,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(160),
          minScale: 0.3,
          maxScale: 3,
          // Plain wheel moves the graph; Ctrl+wheel zooms (InteractiveViewer
          // zooms on every wheel event by itself).
          child: Listener(
            onPointerSignal: (event) {
              if (event is! PointerScrollEvent) return;
              if (HardwareKeyboard.instance.isControlPressed) return;
              GestureBinding.instance.pointerSignalResolver.register(event, (
                e,
              ) {
                final scroll = (e as PointerScrollEvent).scrollDelta;
                _panBy(-scroll);
              });
            },
            child: canvas,
          ),
        );
        if (desktop) {
          viewer = Focus(
            focusNode: _keys,
            onFocusChange: (focused) => setState(() => _keysFocused = focused),
            onKeyEvent: (_, event) => _onKey(event, drawn, focusCentre),
            child: viewer,
          );
        }
        return Stack(
          children: [
            Positioned.fill(child: ClipRect(child: viewer)),
            if (_fitScale < 1)
              Positioned(
                right: 0,
                top: 0,
                child: TextButton.icon(
                  icon: const Icon(Icons.fit_screen_outlined),
                  label: Text(l10n.connectionsFit),
                  onPressed: _fit,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LinesPainter extends CustomPainter {
  const _LinesPainter(this.lines);

  /// From, to, and whether it is the second step.
  final List<(Offset, Offset, bool)> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final near = Paint()
      ..color = connectionLineColor
      ..strokeWidth = 2;
    final far = Paint()
      ..color = connectionFarLineColor
      ..strokeWidth = 1.6;
    for (final (a, b, isFar) in lines) {
      if (isFar) {
        _dashed(canvas, a, b, far);
      } else {
        canvas.drawLine(a, b, near);
      }
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => !listEquals(old.lines, lines);
}

/// The focus in the middle: dark, with its title.
class _FocusPill extends StatelessWidget {
  const _FocusPill({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.inverseSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onInverseSurface,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreNode extends StatelessWidget {
  const _MoreNode({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: StadiumBorder(
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Center(
          child: Text(
            l10n.connectionsMore(count),
            style: theme.textTheme.labelMedium,
          ),
        ),
      ),
    );
  }
}

/// A node with its label: shape, type line, title. A tap focuses, a long
/// press previews; on Windows the mouse pointer shows [preview].
class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.drawn,
    required this.look,
    required this.semantics,
    required this.previewLabel,
    required this.selected,
    required this.desktop,
    required this.preview,
    required this.onTap,
    required this.onLongPress,
    required this.textScale,
  });

  final _Drawn drawn;
  final double textScale;
  final NodeLook look;
  final String semantics;
  final String previewLabel;
  final bool selected;
  final bool desktop;
  final Widget? preview;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = drawn.place;
    final bounds = place.bounds;
    final far = drawn.far;
    final urgent = look.urgency != Urgency.none;
    final label = place.label;
    final scale = TextScaler.linear(textScale);
    Widget tile = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: place.node.left - bounds.left,
          top: place.node.top - bounds.top,
          width: place.node.width,
          height: place.node.height,
          child: _Shape(look: look, far: far, urgent: urgent),
        ),
        if (drawn.behind > 0)
          Positioned(
            left: place.node.right - bounds.left - 6,
            top: place.node.top - bounds.top - 8,
            child: _Badge(count: drawn.behind),
          ),
        if (label != null)
          Positioned(
            left: label.left - bounds.left,
            top: label.top - bounds.top,
            width: label.width,
            height: label.height,
            // The layout gave the room for this text size exactly.
            child: Column(
              children: [
                Text(
                  look.caption.toUpperCase(),
                  textScaler: scale,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  strutStyle: const StrutStyle(
                    fontSize: 9.5,
                    height: 1.26,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 0.2,
                    // Lines pass under the text, not through it.
                    backgroundColor: theme.colorScheme.surface,
                    fontWeight: urgent ? FontWeight.w600 : null,
                    color: urgent
                        ? attentionTextColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  look.title,
                  textScaler: scale,
                  maxLines: place.lines,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  strutStyle: const StrutStyle(
                    fontSize: 12,
                    height: 1.25,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: far ? FontWeight.w400 : FontWeight.w600,
                    backgroundColor: theme.colorScheme.surface,
                    color: far
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
    tile = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: bounds.width,
          height: bounds.height,
          child: tile,
        ),
      ),
    );
    if (preview != null) {
      tile = Tooltip(
        richMessage: WidgetSpan(child: preview!),
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(blurRadius: 12, color: Color(0x40000000)),
          ],
        ),
        excludeFromSemantics: true,
        child: tile,
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: semantics,
      onTap: onTap,
      customSemanticsActions: {
        CustomSemanticsAction(label: previewLabel): onLongPress,
      },
      child: tile,
    );
  }
}

/// The shape of a node (DD-018 point 15): an item a square with its type
/// icon, a person a circle with initials, a project a filled block.
class _Shape extends StatelessWidget {
  const _Shape({required this.look, required this.far, required this.urgent});

  final NodeLook look;
  final bool far;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final outline = urgent
        ? attentionColor
        : far
        ? connectionFarNodeColor
        : calmColor;
    final width = urgent ? 2.5 : 2.0;
    switch (look.node.kind) {
      case NodeKind.project:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: far ? connectionFarProjectColor : calmColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Icon(
            Icons.folder_outlined,
            size: 14,
            color: Colors.white,
          ),
        );
      case NodeKind.person:
        final initials = initialsOf(look.title);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: outline, width: width),
          ),
          child: Center(
            child: Text(
              initials,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: far ? 8.5 : 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B1D20),
              ),
            ),
          ),
        );
      case NodeKind.item:
        final untyped = look.item?.type == null;
        return CustomPaint(
          painter: _SquarePainter(
            color: outline,
            width: width,
            dashed: untyped,
          ),
          child: Center(
            child: Icon(
              nodeIcon(look),
              size: far ? 13 : 16,
              color: far ? connectionFarNodeColor : calmColor,
            ),
          ),
        );
    }
  }
}

class _SquarePainter extends CustomPainter {
  const _SquarePainter({
    required this.color,
    required this.width,
    required this.dashed,
  });

  final Color color;
  final double width;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = Colors.white,
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    if (!dashed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        paint,
      );
      return;
    }
    for (final (a, b) in [
      (rect.topLeft, rect.topRight),
      (rect.topRight, rect.bottomRight),
      (rect.bottomRight, rect.bottomLeft),
      (rect.bottomLeft, rect.topLeft),
    ]) {
      _dashed(canvas, a, b, paint);
    }
  }

  @override
  bool shouldRepaint(_SquarePainter old) =>
      old.color != color || old.width != width || old.dashed != dashed;
}

/// "+7": second-step nodes behind a direct node that are not drawn.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xFF1B1D20),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      '+$count', // l10n-ignore: a number
      textScaler: TextScaler.noScaling,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

/// The preview under the mouse pointer on Windows.
class _HoverCard extends StatelessWidget {
  const _HoverCard({required this.look});

  final NodeLook look;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(look.title, style: theme.textTheme.titleSmall),
            Text(
              look.caption,
              style: look.urgency == Urgency.none
                  ? muted
                  : muted?.copyWith(
                      color: attentionTextColor,
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
