import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../items/item_detail_screen.dart';
import '../tokens/token_editor.dart';
import 'item_panes.dart';

/// The keys of a list of cards on Windows (DD-018 point 5), while the list
/// has the focus (never in a text field): ↑/↓ select a card, Enter opens it
/// (the focus goes to the detail pane, or its screen opens in a narrow
/// window or from a person in the right pane), Delete sends it to the trash and, where [onComplete] is given
/// (Today), Ctrl+Enter completes it; after both the next card is selected.
/// On a phone this adds nothing.
class ListKeys extends ConsumerStatefulWidget {
  const ListKeys({
    super.key,
    required this.ids,
    required this.onTrash,
    this.onComplete,
    this.focusNode,
    this.scope = defaultScope,
    required this.child,
  });

  /// The cards in the order on screen.
  final List<String> ids;

  final ValueChanged<String> onTrash;
  final ValueChanged<String>? onComplete;

  /// The node that holds the list's focus in a narrow window, where there
  /// are no panes: given by a caller that moves the focus into the list
  /// itself (the weekly review, DD-018 point 8).
  final FocusNode? focusNode;

  /// Which list the card keys belong to: a list that can be on screen at
  /// the same time as another with the same items (the weekly review over
  /// *Today* on a phone) has a scope of its own, so no key is used twice.
  final Object scope;
  final Widget child;

  /// The scope of the lists that are never on screen together.
  static const Object defaultScope = #list;

  /// The key of the card of item [id] in [scope], so a selection moved by
  /// the keys can be scrolled into view. Equal for equal ids and scopes, so
  /// a card keeps its element when the list is built again.
  static GlobalKey cardKey(String id, {Object scope = defaultScope}) =>
      _CardKey(scope, id);

  @override
  ConsumerState<ListKeys> createState() => _ListKeysState();
}

/// A global key equal by scope and item id. [GlobalObjectKey] compares its
/// value by identity, and a value built at run time is a new object every
/// time.
@immutable
class _CardKey extends GlobalKey {
  const _CardKey(this.scope, this.id) : super.constructor();

  final Object scope;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is _CardKey && other.scope == scope && other.id == id;

  @override
  int get hashCode => Object.hash(_CardKey, scope, id);
}

class _ListKeysState extends ConsumerState<ListKeys> {
  /// Used in a narrow window, where there are no panes to hold the focus.
  final _ownFocus = FocusNode();

  @override
  void dispose() {
    _ownFocus.dispose();
    super.dispose();
  }

  void _select(String? id) {
    ref.read(selectedItemProvider.notifier).state = id;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final card = ListKeys.cardKey(id, scope: widget.scope).currentContext;
      if (card != null && card.mounted) {
        Scrollable.ensureVisible(
          card,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
        Scrollable.ensureVisible(
          card,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
      }
    });
  }

  /// The card after [id], or before it when it is the last one: what to
  /// select once [id] leaves the list.
  String? _neighbour(String id) {
    final ids = widget.ids;
    final at = ids.indexOf(id);
    if (at < 0 || ids.length == 1) return null;
    return at + 1 < ids.length ? ids[at + 1] : ids[at - 1];
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final ids = widget.ids;
    final selected = ref.read(selectedItemProvider);
    final current = selected != null && ids.contains(selected)
        ? selected
        : null;
    final key = event.logicalKey;
    final control = HardwareKeyboard.instance.isControlPressed;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (ids.isEmpty) return KeyEventResult.handled;
      final at = current == null ? -1 : ids.indexOf(current);
      final next = key == LogicalKeyboardKey.arrowDown
          ? (at + 1).clamp(0, ids.length - 1)
          : (at <= 0 ? 0 : at - 1);
      _select(ids[next]);
      return KeyEventResult.handled;
    }
    if (current == null || event is KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final enter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (enter && control) {
      final complete = widget.onComplete;
      if (complete == null) return KeyEventResult.ignored;
      _select(_neighbour(current));
      complete(current);
      return KeyEventResult.handled;
    }
    if (enter) {
      final panes = ItemPanes.find(context);
      if (panes != null && panes.detailPane) {
        panes.focusDetail();
      } else {
        ItemDetailScreen.open(context, current);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _select(_neighbour(current));
      widget.onTrash(current);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktop(context)) return widget.child;
    return Focus(
      focusNode:
          ItemPanes.maybeOf(context)?.listFocus ??
          widget.focusNode ??
          _ownFocus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
