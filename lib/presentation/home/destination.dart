import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The five destinations (REQ-030, DD-011): the Overview, NL "Inzicht",
/// is the fifth, after People, so Ctrl+3 and Ctrl+4 stay as they were
/// (DD-018 point 12).
enum Destination { today, inbox, projects, people, insights }

/// The destination on screen. The app always starts on Today (DD-011);
/// nothing is remembered between starts.
final destinationProvider = StateProvider<Destination>(
  (ref) => Destination.today,
);
