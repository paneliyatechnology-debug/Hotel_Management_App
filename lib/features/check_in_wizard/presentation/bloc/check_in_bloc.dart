import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../data/models/check_in_form_data.dart';
import '../../../../core/widgets/status_badge.dart';
import 'check_in_event.dart';
import 'check_in_state.dart';

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
    on<SubmitCheckInEvent>(_onSubmitCheckIn);
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

    CheckInFormData initData = CheckInFormData();
    if (event.preselectedRoom != null) {
      initData = CheckInFormData(
        selectedRoomId: event.preselectedRoom!.id,
        selectedRoomNumber: event.preselectedRoom!.roomNumber,
        selectedFloor: event.preselectedRoom!.floor,
        roomType: event.preselectedRoom!.roomType,
        pricePerNight: event.preselectedRoom!.pricePerNight,
        isRoomPreLocked: true,
      );
    } else if (available.isNotEmpty) {
      final firstRoom = available.first;
      initData = CheckInFormData(
        selectedRoomId: firstRoom.id,
        selectedRoomNumber: firstRoom.roomNumber,
        selectedFloor: firstRoom.floor,
        roomType: firstRoom.roomType,
        pricePerNight: firstRoom.pricePerNight,
        isRoomPreLocked: false,
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
    emit(state.copyWith(formData: updated));
  }

  Future<void> _onSubmitCheckIn(
    SubmitCheckInEvent event,
    Emitter<CheckInState> emit,
  ) async {
    emit(state.copyWith(status: CheckInStatus.submitting));
    try {
      final folio = await repository.completeCheckIn(state.formData);
      emit(state.copyWith(
        status: CheckInStatus.success,
        completedFolio: folio,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CheckInStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
