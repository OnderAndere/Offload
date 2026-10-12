import '../../domain/items/item_enums.dart';
import '../../l10n/app_localizations.dart';

/// Names of statuses, types and sources as the screens show them (DD-009).
extension ItemLabels on AppLocalizations {
  String status(ItemStatus status) => switch (status) {
    ItemStatus.inbox => itemStatusInbox,
    ItemStatus.active => itemStatusActive,
    ItemStatus.waiting => itemStatusWaiting,
    ItemStatus.scheduled => itemStatusScheduled,
    ItemStatus.done => itemStatusDone,
    ItemStatus.archived => itemStatusArchived,
  };

  String type(ItemType? type) => switch (type) {
    null => itemTypeNone,
    ItemType.task => itemTypeTask,
    ItemType.request => itemTypeRequest,
    ItemType.idea => itemTypeIdea,
    ItemType.note => itemTypeNote,
  };

  String source(ItemSource source) => switch (source) {
    ItemSource.app => itemSourceApp,
    ItemSource.widget => itemSourceWidget,
    ItemSource.share => itemSourceShare,
    ItemSource.hotkey => itemSourceHotkey,
    ItemSource.tray => itemSourceTray,
    ItemSource.voice => itemSourceVoice,
    ItemSource.handwriting => itemSourceHandwriting,
  };
}
