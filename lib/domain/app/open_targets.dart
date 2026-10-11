/// What the app is asked to open from outside it (REQ-063, DD-010): the
/// Offload bar and the app shortcuts send these, as a tap on a reminder
/// sends an item id, `#review` or `#person:<id>` (DD-005). The Android side
/// uses the same words (`OpenDestinationActivity`).
const openTodayTarget = '#today';
const openInsightsTarget = '#insights';
