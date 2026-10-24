import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../../rooms/data/models/room_model.dart';
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
    final seededRooms = <RoomModel>[
      ...?event.preselectedRooms,
      if (event.preselectedRoom != null) event.preselectedRoom!,
    ];
    final uniqueSeeded = <RoomModel>[];
    for (final room in seededRooms) {
      if (uniqueSeeded.any((item) => item.id == room.id)) continue;
      uniqueSeeded.add(room);
      if (!available.any((item) => item.id == room.id)) {
        available.insert(0, room);
      }
    }

    if (uniqueSeeded.isNotEmpty) {
      final gstRoom = uniqueSeeded.firstWhere(
        (room) => room.gstEnabled,
        orElse: () => uniqueSeeded.first,
      );
      initData = CheckInFormData(
        selectedRoomId: uniqueSeeded.first.id,
        selectedRoomIds: uniqueSeeded.map((room) => room.id).toList(),
        selectedRoomNumber: uniqueSeeded.map((room) => room.roomNumber).join(', '),
        selectedFloor: uniqueSeeded.length == 1
            ? uniqueSeeded.first.floor
            : '${uniqueSeeded.length} rooms',
        roomType: uniqueSeeded.map((room) => room.roomType).toSet().join(' + '),
        pricePerNight: uniqueSeeded.fold<double>(0, (sum, room) => sum + room.pricePerNight),
        gstEnabled: uniqueSeeded.any((room) => room.gstEnabled),
        gstRate: uniqueSeeded.any((room) => room.gstEnabled) ? gstRoom.gstRate : 0,
        isRoomPreLocked: true,
        assignedKeycardNumber: uniqueSeeded.first.keyCode.trim(),
      );
    } else if (available.isNotEmpty) {
      final firstRoom = available.first;
      initData = CheckInFormData(
        selectedRoomId: firstRoom.id,
        selectedRoomIds: [firstRoom.id],
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
    final ids = List<String>.from(updated.selectedRoomIds);
    if (ids.contains(event.room.id)) {
      if (ids.length > 1) ids.remove(event.room.id);
    } else {
      ids.add(event.room.id);
    }
    final selectedRooms = <RoomModel>[];
    for (final id in ids) {
      final match = state.availableRooms.where((room) => room.id == id);
      if (match.isNotEmpty) {
        selectedRooms.add(match.first);
      } else if (event.room.id == id) {
        selectedRooms.add(event.room);
      }
    }
    if (selectedRooms.isEmpty) selectedRooms.add(event.room);
    updated.selectedRoomIds = selectedRooms.map((room) => room.id).toList();
    updated.selectedRoomId = selectedRooms.first.id;
    updated.selectedRoomNumber = selectedRooms.map((room) => room.roomNumber).join(', ');
    updated.selectedFloor = selectedRooms.length == 1
        ? selectedRooms.first.floor
        : '${selectedRooms.length} rooms';
    updated.roomType = selectedRooms.map((room) => room.roomType).toSet().join(' + ');
    updated.pricePerNight =
        selectedRooms.fold<double>(0, (sum, room) => sum + room.pricePerNight);
    updated.gstEnabled = selectedRooms.any((room) => room.gstEnabled);
    final gstRoom = selectedRooms.firstWhere(
      (room) => room.gstEnabled,
      orElse: () => selectedRooms.first,
    );
    updated.gstRate = updated.gstEnabled ? gstRoom.gstRate : 0;
    updated.assignedKeycardNumber = selectedRooms.first.keyCode.trim();
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
