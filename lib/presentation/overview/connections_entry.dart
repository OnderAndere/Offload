import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../home/destination.dart';
import '../review/review_providers.dart';
import 'connections_providers.dart';
import 'insights_screen.dart';

/// *Verbanden tonen* in the ⋮ of an item, a person or a project (DD-018
/// point 15): Insights → Connections with [node] as the focus. What is
/// open over the list closes, and the weekly review gives way, as for the
/// rail (DD-018 point 8).
void showConnectionsOf(BuildContext context, WidgetRef ref, NodeRef node) {
  ref
      .read(connectionsProvider.notifier)
      .focusOn(node, from: ref.read(connectionsFocusProvider));
  ref.read(weeklyReviewOpenProvider.notifier).state = false;
  ref.read(weeklyReviewWideProvider.notifier).state = false;
  ref.read(insightsSegmentProvider.notifier).state =
      InsightsSegment.connections;
  ref.read(destinationProvider.notifier).state = Destination.insights;
  Navigator.of(context).popUntil((route) => route.isFirst);
}
