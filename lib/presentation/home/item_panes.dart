import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// From this window width (logical pixels, Material's "expanded") the list
/// and the item detail are two panes on Windows (DD-018 point 5).
const twoPaneMinWidth = 840.0;

/// The item selected in the list pane on Windows (DD-018 point 5); null
/// when none is. Switching destination clears it.
final selectedItemProvider = StateProvider<String?>((ref) => null);

/// The two panes on a wide Windows window (DD-018 point 5): opening an
/// item selects it in the list and shows it in the detail pane beside it,
/// instead of opening a screen over the list. Without this above it (a
/// phone, a narrow window) opening an item opens its screen.
class ItemPanes extends InheritedWidget {
  const ItemPanes({
    super.key,
    required this.select,
    required this.listFocus,
    required this.detailFocusRequests,
    this.detailPane = true,
    required super.child,
  });

  /// Selects item [id]: the detail pane shows it.
  final ValueChanged<String?> select;

  /// The focus of the list pane, where the list keys work; the detail
  /// hands it back with Escape.
  final FocusNode listFocus;

  /// Counts the requests to put the focus in the text of the item in the
  /// detail pane; the detail listens.
  final ValueNotifier<int> detailFocusRequests;

  /// Whether a detail pane shows the selected item. Not for the lists of a
  /// person in the right pane (DD-018 point 11): Enter there opens the item
  /// through [select].
  final bool detailPane;

  /// Puts the focus in the text of the item in the detail pane (Enter in
  /// the list).
  void focusDetail() => detailFocusRequests.value++;

  /// The panes around [context], or null when there are none.
  static ItemPanes? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ItemPanes>();

  /// The panes around [context] without depending on them: for a tap.
  static ItemPanes? find(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ItemPanes>();

  @override
  bool updateShouldNotify(ItemPanes oldWidget) =>
      select != oldWidget.select ||
      listFocus != oldWidget.listFocus ||
      detailFocusRequests != oldWidget.detailFocusRequests ||
      detailPane != oldWidget.detailPane;
}
