import '../../data/models/check_in_form_data.dart';
import '../../../rooms/data/models/room_model.dart';

abstract class CheckInEvent {}

class InitCheckInWizardEvent extends CheckInEvent {
  final RoomModel? preselectedRoom;
  final List<RoomModel>? preselectedRooms;
  final CheckInFormData? existingForm;
  InitCheckInWizardEvent({
    this.preselectedRoom,
    this.preselectedRooms,
    this.existingForm,
  });
}

class NextStepEvent extends CheckInEvent {}

class PreviousStepEvent extends CheckInEvent {}

class GoToStepEvent extends CheckInEvent {
  final int step;
  GoToStepEvent(this.step);
}

class UpdateFormDataEvent extends CheckInEvent {
  final CheckInFormData updatedData;
  UpdateFormDataEvent(this.updatedData);
}

class SelectRoomForCheckInEvent extends CheckInEvent {
  final RoomModel room;
  SelectRoomForCheckInEvent(this.room);
}

class SubmitCheckInEvent extends CheckInEvent {}

class SetValidationErrorsEvent extends CheckInEvent {
  final bool show;
  SetValidationErrorsEvent(this.show);
}
