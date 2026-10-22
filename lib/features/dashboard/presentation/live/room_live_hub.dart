import 'package:flutter/widgets.dart';

import '../../data/models/room_live_update.dart';

class RoomLiveHub extends ChangeNotifier {
  static final RoomLiveHub instance = RoomLiveHub();

  RoomPatch? room;
  RoomBreakdown? breakdown;

  void publish(RoomLiveUpdate update) {
    if (update.room != null) room = update.room;
    if (update.breakdown != null) breakdown = update.breakdown;
    notifyListeners();
  }

  void requestRefresh() {
    notifyListeners();
  }

  void clear() {
    room = null;
    breakdown = null;
  }
}
