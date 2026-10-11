import 'package:offload/presentation/home/destination.dart';

/// Starts the app on the Inbox instead of Today (DD-011), for the tests of
/// screens reached from the inbox; the navigation tests start on Today.
final startOnInbox = destinationProvider.overrideWith(
  (ref) => Destination.inbox,
);
