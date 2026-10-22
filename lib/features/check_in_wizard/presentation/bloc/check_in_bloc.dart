import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../data/models/check_in_form_data.dart';
import '../../../../core/widgets/status_badge.dart';
import 'check_in_event.dart';
import 'check_in_state.dart';

String _checkInErrorText(Object error) {
  var text = error.toString();
  text = text.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
  text = text.replaceFirst(RegExp(r'^Unsupported operation:\s*'), '');
  return text.trim().isEmpty ? 'Check-in failed' : text.trim();
}

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final IDashboardRepository repository;

  CheckInBloc({required this.repository, CheckInFormData? initialFormData})
      : super(CheckInState(formData: initialFormData ?? CheckInFormData())) {
    on<InitCheckInWizardEvent>(_onInit);
    on<NextStepEvent>(_onNextStep);
    on<PreviousStepEvent>(_onPreviousStep);
    on<GoToStepEvent>(_onGoToStep);
    on<UpdateFormDataEvent>(_onUpdateFormData);
    on<SelectRoomForCheckInEvent>(_onSelectRoom);
    on<SubmitCheckInEvent>(_onSubmitCheckIn, transformer: _dropWhileBusy());
    on<SetValidationErrorsEvent>(_onSetValidationErrors);
  }

  void _onSetValidationErrors(
    SetValidationErrorsEvent event,
    Emitter<CheckInState> emit,
  ) {
    emit(state.copyWith(showValidationErrors: event.show));
  }

  Future<void> _onInit(
    InitCheckInWizardEvent event,
    Emitter<CheckInState> emit,
  ) async {
    final allRooms = await repository.getRooms();
    final available = allRooms.where((r) => r.status == RoomStatus.available).toList();
    if (event.existingForm != null) {
      final current = event.preselectedRoom;
      if (current != null && !available.any((room) => room.id == current.id)) {
        available.insert(0, current);
      }
      emit(state.copyWith(
        currentStep: 0,
        formData: event.existingForm!.copy(),
        availableRooms: available,
        status: CheckInStatus.editing,
        showValidationErrors: false,
      ));
      return;
    }

    CheckInFormData initData = CheckInFormData();
    if (event.preselectedRoom != null) {
      initData = CheckInFormData(
        selectedRoomId: event.preselectedRoom!.id,
        selectedRoomNumber: event.preselectedRoom!.roomNumber,
        selectedFloor: event.preselectedRoom!.floor,
        roomType: event.preselectedRoom!.roomType,
        pricePerNight: event.preselectedRoom!.pricePerNight,
        gstEnabled: event.preselectedRoom!.gstEnabled,
        gstRate: event.preselectedRoom!.gstEnabled ? event.preselectedRoom!.gstRate : 0,
        isRoomPreLocked: true,
        assignedKeycardNumber: event.preselectedRoom!.keyCode.trim(),
      );
    } else if (available.isNotEmpty) {
      final firstRoom = available.first;
      initData = CheckInFormData(
        selectedRoomId: firstRoom.id,
        selectedRoomNumber: firstRoom.roomNumber,
        selectedFloor: firstRoom.floor,
        roomType: firstRoom.roomType,
        pricePerNight: firstRoom.pricePerNight,
        gstEnabled: firstRoom.gstEnabled,
        gstRate: firstRoom.gstEnabled ? firstRoom.gstRate : 0,
        isRoomPreLocked: false,
        assignedKeycardNumber: firstRoom.keyCode.trim(),
      );
    }

    if (initData.roomType.toLowerCase().contains('family')) {
      initData.accompanyingGuests = [
        AccompanyingGuest(
          name: '',
          relationship: 'Spouse',
          idType: 'Aadhaar Card',
          idNumber: '',
          isIdVerified: false,
        ),
        AccompanyingGuest(
          name: '',
          relationship: 'Child',
          idType: 'Aadhaar Card',
          idNumber: '',
          isIdVerified: false,
        ),
      ];
      initData.partyType = 'Family / Group';
      initData.numberOfGuests = 3;
    } else if (initData.roomType.toLowerCase().contains('couple')) {
      initData.accompanyingGuests = [
        AccompanyingGuest(
          name: '',
          relationship: 'Spouse',
          idType: 'Aadhaar Card',
          idNumber: '',
          isIdVerified: false,
        ),
      ];
      initData.partyType = 'Couple (2 Guests)';
      initData.numberOfGuests = 2;
    }

    emit(state.copyWith(
      currentStep: 0,
      formData: initData,
      availableRooms: available,
      status: CheckInStatus.editing,
      showValidationErrors: false,
    ));
  }

  void _onNextStep(
    NextStepEvent event,
    Emitter<CheckInState> emit,
  ) {
    if (state.currentStep < 3) {
      emit(state.copyWith(
        currentStep: state.currentStep + 1,
        showValidationErrors: false,
      ));
    }
  }

  void _onPreviousStep(
    PreviousStepEvent event,
    Emitter<CheckInState> emit,
  ) {
    if (state.currentStep > 0) {
      emit(state.copyWith(
        currentStep: state.currentStep - 1,
        showValidationErrors: false,
      ));
    }
  }

  void _onGoToStep(
    GoToStepEvent event,
    Emitter<CheckInState> emit,
  ) {
    if (event.step >= 0 && event.step <= 3) {
      emit(state.copyWith(
        currentStep: event.step,
        showValidationErrors: false,
      ));
    }
  }

  void _onUpdateFormData(
    UpdateFormDataEvent event,
    Emitter<CheckInState> emit,
  ) {
    emit(state.copyWith(formData: event.updatedData));
  }

  void _onSelectRoom(
    SelectRoomForCheckInEvent event,
    Emitter<CheckInState> emit,
  ) {
    final updated = state.formData.copy();
    updated.selectedRoomId = event.room.id;
    updated.selectedRoomNumber = event.room.roomNumber;
    updated.selectedFloor = event.room.floor;
    updated.roomType = event.room.roomType;
    updated.pricePerNight = event.room.pricePerNight;
    updated.gstEnabled = event.room.gstEnabled;
    updated.gstRate = event.room.gstEnabled ? event.room.gstRate : 0;
    updated.assignedKeycardNumber = event.room.keyCode.trim();
    emit(state.copyWith(formData: updated));
  }

  Future<void> _onSubmitCheckIn(
    SubmitCheckInEvent event,
    Emitter<CheckInState> emit,
  ) async {
    if (state.status == CheckInStatus.submitting || state.status == CheckInStatus.success) {
      return;
    }
    emit(state.copyWith(status: CheckInStatus.submitting));
    try {
      final folio = state.formData.isEditingBooking
          ? await repository.updateBookingFromForm(state.formData)
          : await repository.completeCheckIn(state.formData);
      emit(state.copyWith(
        status: CheckInStatus.success,
        completedFolio: folio,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CheckInStatus.error,
        errorMessage: _checkInErrorText(e),
      ));
    }
  }
}

/// Ignores extra check-in taps until the booking request that is already
/// running has finished.
EventTransformer<E> _dropWhileBusy<E>() {
  return (events, mapper) {
    final controller = StreamController<E>.broadcast(sync: true);
    var busy = false;
    final subscription = events.listen((event) {
      if (busy) return;
      busy = true;
      mapper(event).listen(
        controller.add,
        onError: controller.addError,
        onDone: () => busy = false,
        cancelOnError: false,
      );
    }, onError: controller.addError);
    controller.onCancel = subscription.cancel;
    return controller.stream;
  };
}
