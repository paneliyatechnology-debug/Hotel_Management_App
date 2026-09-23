import '../../data/models/check_in_form_data.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';

enum CheckInStatus { initial, editing, submitting, success, error }

class CheckInState {
  final int currentStep; // 0 to 4 (Step 1 to 5)
  final CheckInFormData formData;
  final List<RoomModel> availableRooms;
  final CheckInStatus status;
  final GuestFolioModel? completedFolio;
  final String? errorMessage;
  final bool showValidationErrors;

  const CheckInState({
    this.currentStep = 0,
    required this.formData,
    this.availableRooms = const [],
    this.status = CheckInStatus.initial,
    this.completedFolio,
    this.errorMessage,
    this.showValidationErrors = false,
  });

  CheckInState copyWith({
    int? currentStep,
    CheckInFormData? formData,
    List<RoomModel>? availableRooms,
    CheckInStatus? status,
    GuestFolioModel? completedFolio,
    String? errorMessage,
    bool? showValidationErrors,
  }) {
    return CheckInState(
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
      availableRooms: availableRooms ?? this.availableRooms,
      status: status ?? this.status,
      completedFolio: completedFolio ?? this.completedFolio,
      errorMessage: errorMessage ?? this.errorMessage,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
    );
  }
}
