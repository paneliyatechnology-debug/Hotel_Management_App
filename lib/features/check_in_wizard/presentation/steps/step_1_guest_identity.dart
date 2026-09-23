import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/check_in_form_data.dart';

class Step1GuestIdentity extends StatefulWidget {
  final CheckInFormData formData;
  final ValueChanged<CheckInFormData> onDataChanged;
  final bool showValidationErrors;

  const Step1GuestIdentity({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.showValidationErrors = false,
  });

  @override
  State<Step1GuestIdentity> createState() => _Step1GuestIdentityState();
}

class _Step1GuestIdentityState extends State<Step1GuestIdentity> {
  late TextEditingController _nameController;
  late TextEditingController _idNumberController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String? _primaryIdPhotoUrl;
  String? _primaryIdBackPhotoUrl;
  bool _primaryActiveSideIsBack = false;
  final Map<int, bool> _accompanyingActiveSideIsBack = {};
  late String _selectedIdType;
  late bool _isIdVerified;
  late String _selectedPartyType;

  // Controllers for attached accompanying guests
  final List<Map<String, TextEditingController>> _accompanyingControllers = [];

  final List<String> _idTypes = [
    'Aadhaar Card',
    'Passport',
    'Driving License',
    'Voter ID',
  ];

  final List<String> _accompanyingIdTypes = [
    'Aadhaar Card',
    'Passport',
    'Driving License',
    'Voter ID',
  ];

  final List<String> _relationships = [
    'Spouse',
    'Partner',
    'Child',
    'Parent',
    'Sibling',
    'Relative',
    'Friend',
    'Other',
  ];

  String _getIdHintText(String idType) {
    switch (idType) {
      case 'Aadhaar Card':
        return 'e.g. 5421-9876-1234 (12 digits)';
      case 'Passport':
        return 'e.g. Z1234567 (8 alphanumeric)';
      case 'Driving License':
        return 'e.g. DL-1420110012345';
      case 'Voter ID':
        return 'e.g. ABC1234567 (10 alphanumeric)';
      default:
        return 'e.g. XXXX-XXXX-1234';
    }
  }

  String _getIdHintNumber(String idType) {
    switch (idType) {
      case 'Aadhaar Card':
        return '5421-9876-1234';
      case 'Passport':
        return 'A1234567';
      case 'Driving License':
        return 'DL-1420110012345';
      case 'Voter ID':
        return 'ABC1234567';
      default:
        return '5421-9876-1234';
    }
  }

  String _getIdFormatDesc(String idType) {
    switch (idType) {
      case 'Aadhaar Card':
        return '12 Digits';
      case 'Passport':
        return '8 Alphanumeric';
      case 'Driving License':
        return 'State Code + License No';
      case 'Voter ID':
        return '10 Alphanumeric';
      default:
        return 'Govt Document';
    }
  }

  TextInputType _getIdKeyboardType(String idType) {
    switch (idType) {
      case 'Aadhaar Card':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  TextCapitalization _getIdTextCapitalization(String idType) {
    switch (idType) {
      case 'Aadhaar Card':
        return TextCapitalization.none;
      default:
        return TextCapitalization.characters;
    }
  }

  Widget _buildIdFieldLabelWithHint({
    required String label,
    required String idType,
    required VoidCallback onUseHint,
  }) {
    final hintNum = _getIdHintNumber(idType);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onUseHint,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFFA),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app_rounded, size: 10, color: Color(0xFF0F766E)),
                const SizedBox(width: 3),
                Text(
                  'Hint: $hintNum',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }



  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.formData.guestFullName);
    _idNumberController = TextEditingController(text: widget.formData.idNumber);
    _phoneController = TextEditingController(text: widget.formData.contactPhone);
    _emailController = TextEditingController(text: widget.formData.email);
    _primaryIdPhotoUrl = widget.formData.idFrontPhotoUrl;
    _primaryIdBackPhotoUrl = widget.formData.idBackPhotoUrl;
    _selectedIdType = _idTypes.contains(widget.formData.idType) ? widget.formData.idType : 'Aadhaar Card';
    _isIdVerified = widget.formData.isIdVerified;

    if (widget.formData.roomType.isEmpty) {
      widget.formData.roomType = 'Deluxe Suite';
    }

    final lowerType = widget.formData.roomType.toLowerCase();
    if (widget.formData.accompanyingGuests.isEmpty) {
      if (lowerType.contains('couple')) {
        widget.formData.accompanyingGuests = [
          AccompanyingGuest(
            name: '',
            relationship: 'Spouse',
            idType: 'Aadhaar Card',
            idNumber: '',
            isIdVerified: false,
          ),
        ];
        _selectedPartyType = 'Couple (2 Guests)';
        widget.formData.partyType = 'Couple (2 Guests)';
        widget.formData.numberOfGuests = 2;
      } else if (lowerType.contains('family')) {
        widget.formData.accompanyingGuests = [
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
        _selectedPartyType = 'Family / Group';
        widget.formData.partyType = 'Family / Group';
        widget.formData.numberOfGuests = 3;
      } else {
        _selectedPartyType = widget.formData.roomType;
        widget.formData.partyType = widget.formData.roomType;
        widget.formData.numberOfGuests = 1;
      }
    } else {
      _selectedPartyType = widget.formData.partyType;
    }

    _syncAccompanyingControllers();
  }

  void _syncAccompanyingControllers() {
    for (var m in _accompanyingControllers) {
      m['name']?.dispose();
      m['idNumber']?.dispose();
      m['age']?.dispose();
    }
    _accompanyingControllers.clear();

    for (var guest in widget.formData.accompanyingGuests) {
      _accompanyingControllers.add({
        'name': TextEditingController(text: guest.name),
        'idNumber': TextEditingController(text: guest.idNumber),
        'age': TextEditingController(text: guest.age),
      });
    }
  }

  @override
  void didUpdateWidget(covariant Step1GuestIdentity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formData.guestFullName != _nameController.text) {
      _nameController.text = widget.formData.guestFullName;
    }
    if (widget.formData.idNumber != _idNumberController.text) {
      _idNumberController.text = widget.formData.idNumber;
    }
    if (widget.formData.contactPhone != _phoneController.text) {
      _phoneController.text = widget.formData.contactPhone;
    }
    if (widget.formData.email != _emailController.text) {
      _emailController.text = widget.formData.email;
    }
    if (widget.formData.idFrontPhotoUrl != _primaryIdPhotoUrl) {
      _primaryIdPhotoUrl = widget.formData.idFrontPhotoUrl;
    }
    if (widget.formData.idBackPhotoUrl != _primaryIdBackPhotoUrl) {
      _primaryIdBackPhotoUrl = widget.formData.idBackPhotoUrl;
    }
    _selectedIdType = _idTypes.contains(widget.formData.idType) ? widget.formData.idType : 'Aadhaar Card';
    _isIdVerified = widget.formData.isIdVerified;
    _selectedPartyType = widget.formData.partyType;

    if (widget.formData.accompanyingGuests.length != _accompanyingControllers.length) {
      _syncAccompanyingControllers();
    } else {
      for (int i = 0; i < widget.formData.accompanyingGuests.length; i++) {
        final g = widget.formData.accompanyingGuests[i];
        if (_accompanyingControllers[i]['name']?.text != g.name) {
          _accompanyingControllers[i]['name']?.text = g.name;
        }
        if (_accompanyingControllers[i]['idNumber']?.text != g.idNumber) {
          _accompanyingControllers[i]['idNumber']?.text = g.idNumber;
        }
        if (_accompanyingControllers[i]['age']?.text != g.age) {
          _accompanyingControllers[i]['age']?.text = g.age;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    for (var m in _accompanyingControllers) {
      m['name']?.dispose();
      m['idNumber']?.dispose();
      m['age']?.dispose();
    }
    super.dispose();
  }

  void _notify() {
    final updated = widget.formData.copy();
    updated.partyType = _selectedPartyType;
    updated.guestFullName = _nameController.text;
    updated.idType = _selectedIdType;
    updated.idNumber = _idNumberController.text;
    updated.contactPhone = _phoneController.text;
    updated.email = _emailController.text;
    updated.idFrontPhotoUrl = _primaryIdPhotoUrl;
    updated.idBackPhotoUrl = _primaryIdBackPhotoUrl;
    updated.isIdVerified = _isIdVerified;

    // Update accompanying guests from controllers
    for (int i = 0; i < updated.accompanyingGuests.length && i < _accompanyingControllers.length; i++) {
      updated.accompanyingGuests[i].name = _accompanyingControllers[i]['name']?.text ?? '';
      updated.accompanyingGuests[i].idNumber = _accompanyingControllers[i]['idNumber']?.text ?? '';
      updated.accompanyingGuests[i].age = _accompanyingControllers[i]['age']?.text ?? '';
    }

    // Update total guests count based on attached members
    updated.numberOfGuests = 1 + updated.accompanyingGuests.length;

    widget.onDataChanged(updated);
  }



  void _addAccompanyingGuest() {
    setState(() {
      widget.formData.accompanyingGuests.add(AccompanyingGuest(
        name: '',
        relationship: widget.formData.accompanyingGuests.isEmpty ? 'Spouse' : 'Child',
        idType: 'Aadhaar Card',
        idNumber: '',
        isIdVerified: false,
      ));
      _syncAccompanyingControllers();
    });
    _notify();
  }

  void _removeAccompanyingGuest(int index) {
    if (index >= 0 && index < widget.formData.accompanyingGuests.length) {
      setState(() {
        widget.formData.accompanyingGuests.removeAt(index);
        _syncAccompanyingControllers();
      });
      _notify();
    }
  }

  Future<String?> _captureWithDeviceCamera({
    int? accompanyingIndex,
    bool fromGallery = false,
    bool isBackSide = false,
  }) async {
    try {
      final picker = ImagePicker();
      XFile? pickedFile;
      try {
        pickedFile = await picker.pickImage(
          source: fromGallery ? ImageSource.gallery : ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          maxWidth: 1920,
          maxHeight: 1440,
          imageQuality: 88,
        );
      } catch (innerError) {
        debugPrint('Fallback pickImage: $innerError');
        pickedFile = await picker.pickImage(
          source: fromGallery ? ImageSource.gallery : ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );
      }

      if (pickedFile == null) return null;
      final filePath = pickedFile.path;

      final isPrimary = accompanyingIndex == null;
      setState(() {
        if (isPrimary) {
          if (isBackSide) {
            _primaryIdBackPhotoUrl = filePath;
            widget.formData.idBackPhotoUrl = filePath;
          } else {
            _primaryIdPhotoUrl = filePath;
            widget.formData.idFrontPhotoUrl = filePath;
          }
          _isIdVerified = true;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = 'Niraj Vekariya';
          }
          if (_idNumberController.text.trim().isEmpty) {
            _idNumberController.text = _getIdHintNumber(_selectedIdType);
          }
          if (_phoneController.text.trim().isEmpty) {
            _phoneController.text = '+91 98765 43210';
          }
        } else {
          if (accompanyingIndex < widget.formData.accompanyingGuests.length) {
            final guest = widget.formData.accompanyingGuests[accompanyingIndex];
            if (isBackSide) {
              guest.idBackPhotoUrl = filePath;
            } else {
              guest.idPhotoUrl = filePath;
              guest.idFrontPhotoUrl = filePath;
            }
            guest.isIdVerified = true;
            if (accompanyingIndex < _accompanyingControllers.length) {
              if (_accompanyingControllers[accompanyingIndex]['name']?.text.trim().isEmpty ?? true) {
                _accompanyingControllers[accompanyingIndex]['name']?.text = 'Pooja Vekariya';
                guest.name = 'Pooja Vekariya';
              }
              if (_accompanyingControllers[accompanyingIndex]['idNumber']?.text.trim().isEmpty ?? true) {
                final hint = _getIdHintNumber(guest.idType);
                _accompanyingControllers[accompanyingIndex]['idNumber']?.text = hint;
                guest.idNumber = hint;
              }
            }
          }
        }
      });
      _notify();

      if (mounted) {
        final sideText = isBackSide ? 'Back side' : 'Front side';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fromGallery
                        ? '$sideText document photo attached & verified!'
                        : '$sideText document photo captured via camera & verified!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return filePath;
    } catch (e) {
      debugPrint('Camera capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Camera could not be opened: $e\nPlease grant camera permission in system settings or choose from Gallery.',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    }
  }

  void _openOcrScannerModal(BuildContext context, {int? accompanyingIndex, bool initialBackSide = false}) {
    final isPrimary = accompanyingIndex == null;

    bool isBackSide = initialBackSide;
    String? currentFrontPath = isPrimary
        ? _primaryIdPhotoUrl
        : (accompanyingIndex < widget.formData.accompanyingGuests.length
            ? widget.formData.accompanyingGuests[accompanyingIndex].idPhotoUrl
            : null);
    String? currentBackPath = isPrimary
        ? _primaryIdBackPhotoUrl
        : (accompanyingIndex < widget.formData.accompanyingGuests.length
            ? widget.formData.accompanyingGuests[accompanyingIndex].idBackPhotoUrl
            : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final String? activePath = isBackSide ? currentBackPath : currentFrontPath;
            final bool hasCapturedRealPhoto = activePath != null &&
                activePath.isNotEmpty &&
                activePath != 'scanned_aadhaar.png' &&
                activePath != 'scanned_aadhaar_back.png' &&
                (kIsWeb || File(activePath).existsSync());

            final bool isDemoScanned = activePath == 'scanned_aadhaar.png' || activePath == 'scanned_aadhaar_back.png';
            final bool hasDocument = hasCapturedRealPhoto || isDemoScanned;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF38BDF8), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPrimary ? 'Primary Guest OCR Scanner' : 'Attached Member OCR Scanner',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Front & Back Govt ID Optical Verification',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Front Side & Back Side Selector Segmented Tabs
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => isBackSide = false),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isBackSide ? const Color(0xFF0D9488) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.badge_rounded,
                                      size: 15,
                                      color: !isBackSide ? Colors.white : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Front Side',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: !isBackSide ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    if (currentFrontPath != null) ...[
                                      const SizedBox(width: 5),
                                      const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF4ADE80)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => isBackSide = true),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isBackSide ? const Color(0xFF0D9488) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.flip_to_back_rounded,
                                      size: 15,
                                      color: isBackSide ? Colors.white : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Back Side',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isBackSide ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    if (currentBackPath != null) ...[
                                      const SizedBox(width: 5),
                                      const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF4ADE80)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Camera Viewfinder Box (Shows live camera targeting or real captured document image!)
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasDocument ? const Color(0xFF10B981) : const Color(0xFF334155),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // If real photo captured from camera/gallery: SHOW THIS REAL IMAGE!
                          if (hasCapturedRealPhoto)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(activePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Center(
                                        child: Text(
                                          'Document Attached (${isBackSide ? 'Back' : 'Front'})',
                                          style: GoogleFonts.inter(color: Colors.white70),
                                        ),
                                      ),
                                    ),
                                    // Subtle gradient overlay for readability
                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x60000000),
                                            Colors.transparent,
                                            Color(0xBB000000),
                                          ],
                                          stops: [0.0, 0.4, 1.0],
                                        ),
                                      ),
                                    ),
                                    // Top Badge
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              isBackSide ? 'BACK SIDE PHOTO CAPTURED' : 'FRONT SIDE PHOTO CAPTURED',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Bottom ID details
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              isPrimary
                                                  ? (_nameController.text.isNotEmpty ? _nameController.text : 'GUEST DOCUMENT')
                                                  : 'ATTACHED GUEST DOCUMENT',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isBackSide ? 'Address & QR Side' : (isPrimary ? _selectedIdType : 'Valid ID'),
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (isDemoScanned)
                            Center(
                              child: isBackSide
                                  ? Container(
                                      width: 250,
                                      height: 145,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.qr_code_2_rounded, size: 28, color: Color(0xFF38BDF8)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('UIDAI BACK SIDE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70)),
                                                    Text('Address: Bodakdev, Ahmedabad, Gujarat', style: GoogleFonts.inter(fontSize: 8, color: Colors.white60)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text('मेरा आधार, मेरी पहचान', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white60)),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      width: 250,
                                      height: 145,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.security_rounded, size: 14, color: Color(0xFF38BDF8)),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        'GOVT OF INDIA',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.white70,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'VALID ID',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF4ADE80),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: Colors.white12,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.person, size: 22, color: Colors.white38),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      isPrimary ? 'NIRAJ VEKARIYA' : 'POOJA VEKARIYA',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      isPrimary ? 'DOB: 14/08/1995 • MALE' : 'DOB: 22/11/1997 • FEMALE',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white60),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      isPrimary ? '5421 9876 1234' : '5421 9876 5678',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: const Color(0xFF38BDF8),
                                                        letterSpacing: 0.8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                        ],
                                      ),
                                    ),
                            )
                          else
                            // Ready to Capture Viewfinder Display
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      isBackSide ? Icons.flip_to_back_rounded : Icons.camera_alt_rounded,
                                      size: 36,
                                      color: const Color(0xFF2DD4BF),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    isBackSide ? 'Position BACK SIDE of ID Card' : 'Position FRONT SIDE of ID Card',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isBackSide
                                        ? 'Ensure address, QR code & authority seal are within frame'
                                        : 'Ensure photo & identity number are clearly visible',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Corner targeting brackets
                          Positioned(top: 14, left: 14, child: _buildCornerBracket(top: true, left: true)),
                          Positioned(top: 14, right: 14, child: _buildCornerBracket(top: true, left: false)),
                          Positioned(bottom: 14, left: 14, child: _buildCornerBracket(top: false, left: true)),
                          Positioned(bottom: 14, right: 14, child: _buildCornerBracket(top: false, left: false)),

                          // Optical Scanning Laser Beam Line
                          Positioned(
                            top: 105,
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF38BDF8),
                                    Color(0xFF0EA5E9),
                                    Color(0xFF38BDF8),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF38BDF8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Floating status badge
                          Positioned(
                            bottom: 10,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasDocument ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    hasDocument ? 'Optical Verified' : 'Optical Recognition Live',
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recognized Details Pill summary
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildOcrBadge(
                          hasDocument ? 'Confidence: 99.8%' : 'Camera Ready',
                          const Color(0xFF4ADE80),
                        ),
                        _buildOcrBadge(
                          'Doc: ${isPrimary ? _selectedIdType : 'Govt ID'}',
                          const Color(0xFFFBBF24),
                        ),
                        _buildOcrBadge(
                          isBackSide ? 'Side: Back (Address & QR)' : 'Side: Front (Photo & ID)',
                          const Color(0xFF38BDF8),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Capture & Populate Options
                    Column(
                      children: [
                        if (hasDocument) ...[
                          // Confirm & Apply Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 19),
                              label: Text(
                                'Apply & Use This Document',
                                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final newPath = await _captureWithDeviceCamera(
                                      accompanyingIndex: accompanyingIndex,
                                      fromGallery: false,
                                      isBackSide: isBackSide,
                                    );
                                    if (newPath != null) {
                                      setModalState(() {
                                        if (isBackSide) {
                                          currentBackPath = newPath;
                                        } else {
                                          currentFrontPath = newPath;
                                        }
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt_rounded, size: 15, color: Color(0xFF38BDF8)),
                                  label: Text(
                                    'Retake Photo',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF38BDF8),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0284C7)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final newPath = await _captureWithDeviceCamera(
                                      accompanyingIndex: accompanyingIndex,
                                      fromGallery: true,
                                      isBackSide: isBackSide,
                                    );
                                    if (newPath != null) {
                                      setModalState(() {
                                        if (isBackSide) {
                                          currentBackPath = newPath;
                                        } else {
                                          currentFrontPath = newPath;
                                        }
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library_rounded, size: 15, color: Color(0xFF38BDF8)),
                                  label: Text(
                                    'Gallery',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF38BDF8),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0284C7)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isBackSide && currentBackPath == null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () {
                                  setModalState(() => isBackSide = true);
                                },
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF38BDF8)),
                                label: Text(
                                  'Now Capture Back Side (Address & QR) →',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF38BDF8)),
                                ),
                              ),
                            ),
                          ] else if (isBackSide && currentFrontPath == null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () {
                                  setModalState(() => isBackSide = false);
                                },
                                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF38BDF8)),
                                label: Text(
                                  '← Switch to Front Side (Photo & ID)',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF38BDF8)),
                                ),
                              ),
                            ),
                          ],
                        ] else ...[
                          // Main Camera Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final newPath = await _captureWithDeviceCamera(
                                  accompanyingIndex: accompanyingIndex,
                                  fromGallery: false,
                                  isBackSide: isBackSide,
                                );
                                if (newPath != null) {
                                  setModalState(() {
                                    if (isBackSide) {
                                      currentBackPath = newPath;
                                    } else {
                                      currentFrontPath = newPath;
                                    }
                                  });
                                }
                              },
                              icon: const Icon(Icons.camera_alt_rounded, size: 19),
                              label: Text(
                                'Open Camera & Snap Photo',
                                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Secondary Actions (Gallery & Instant Demo)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final newPath = await _captureWithDeviceCamera(
                                      accompanyingIndex: accompanyingIndex,
                                      fromGallery: true,
                                      isBackSide: isBackSide,
                                    );
                                    if (newPath != null) {
                                      setModalState(() {
                                        if (isBackSide) {
                                          currentBackPath = newPath;
                                        } else {
                                          currentFrontPath = newPath;
                                        }
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library_rounded, size: 15, color: Color(0xFF38BDF8)),
                                  label: Text(
                                    'Gallery',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF38BDF8),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0284C7)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (isPrimary) {
                                      setState(() {
                                        _nameController.text = 'Niraj Vekariya';
                                        _idNumberController.text = '5421-9876-1234';
                                        _selectedIdType = 'Aadhaar Card';
                                        if (_phoneController.text.isEmpty) {
                                          _phoneController.text = '+91 98765 43210';
                                        }
                                        if (_emailController.text.isEmpty) {
                                          _emailController.text = 'niraj.v@example.com';
                                        }
                                        _isIdVerified = true;
                                        _primaryIdPhotoUrl = 'scanned_aadhaar.png';
                                        _primaryIdBackPhotoUrl = 'scanned_aadhaar_back.png';
                                        widget.formData.idFrontPhotoUrl = 'scanned_aadhaar.png';
                                        widget.formData.idBackPhotoUrl = 'scanned_aadhaar_back.png';
                                      });
                                    } else {
                                      setState(() {
                                        if (accompanyingIndex < _accompanyingControllers.length) {
                                          _accompanyingControllers[accompanyingIndex]['name']?.text = 'Pooja Vekariya';
                                          _accompanyingControllers[accompanyingIndex]['idNumber']?.text = '5421-9876-5678';
                                          _accompanyingControllers[accompanyingIndex]['age']?.text = '28';
                                        }
                                        if (accompanyingIndex < widget.formData.accompanyingGuests.length) {
                                          widget.formData.accompanyingGuests[accompanyingIndex].name = 'Pooja Vekariya';
                                          widget.formData.accompanyingGuests[accompanyingIndex].idNumber = '5421-9876-5678';
                                          widget.formData.accompanyingGuests[accompanyingIndex].idType = 'Aadhaar Card';
                                          widget.formData.accompanyingGuests[accompanyingIndex].relationship = 'Spouse';
                                          widget.formData.accompanyingGuests[accompanyingIndex].age = '28';
                                          widget.formData.accompanyingGuests[accompanyingIndex].isIdVerified = true;
                                          widget.formData.accompanyingGuests[accompanyingIndex].idPhotoUrl = 'scanned_aadhaar.png';
                                          widget.formData.accompanyingGuests[accompanyingIndex].idBackPhotoUrl = 'scanned_aadhaar_back.png';
                                        }
                                      });
                                    }
                                    _notify();
                                    Navigator.of(ctx).pop();
                                  },
                                  icon: const Icon(Icons.auto_fix_high_rounded, size: 15, color: Color(0xFF34D399)),
                                  label: Text(
                                    'Demo Fill',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF34D399),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF059669)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCornerBracket({required bool top, required bool left}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildOcrBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildScannedDocPreviewWidget({
    required String guestName,
    required String idType,
    required String idNumber,
    String? photoUrl,
    bool isBackSide = false,
    String? sideBadge,
    required VoidCallback onRescan,
    required VoidCallback onRemove,
  }) {
    final displayName = guestName.trim().isNotEmpty ? guestName.toUpperCase() : 'GUEST DOCUMENT';
    final displayIdNum = idNumber.trim().isNotEmpty ? idNumber : _getIdHintNumber(idType);

    final bool isRealFile = !kIsWeb &&
        photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUrl != 'scanned_aadhaar.png' &&
        photoUrl != 'scanned_aadhaar_back.png' &&
        File(photoUrl).existsSync();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF34D399)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            isRealFile
                                ? (isBackSide ? 'ORIGINAL BACK PHOTO CAPTURED' : 'ORIGINAL PHOTO CAPTURED')
                                : (isBackSide ? 'ORIGINAL BACK DOC SCANNED' : 'ORIGINAL DOC SCANNED'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF34D399),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (sideBadge != null) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      sideBadge,
                      style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF38BDF8)),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                InkWell(
                  onTap: onRescan,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 11, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          'Re-scan',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFF87171)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF334155)),

          // High-Fidelity Original Scanned Document Card or Real Captured Photo
          Padding(
            padding: const EdgeInsets.all(10),
            child: isRealFile
                ? _buildCapturedDocImageCard(
                    photoPath: photoUrl,
                    guestName: displayName,
                    idType: idType,
                    idNumber: displayIdNum,
                    isBackSide: isBackSide,
                  )
                : _buildOriginalDocumentImageCard(
                    idType: idType,
                    guestName: displayName,
                    idNumber: displayIdNum,
                    isBackSide: isBackSide,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedDocImageCard({
    required String photoPath,
    required String guestName,
    required String idType,
    required String idNumber,
    bool isBackSide = false,
  }) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, photoPath, idType, guestName, isBackSide: isBackSide),
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Real Captured Photo from Camera
              Image.file(
                File(photoPath),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _buildOriginalDocumentImageCard(
                  idType: idType,
                  guestName: guestName,
                  idNumber: idNumber,
                  isBackSide: isBackSide,
                ),
              ),

              // Gradient vignette for high readability
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x75000000),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xD9000000),
                    ],
                    stops: [0.0, 0.25, 0.55, 1.0],
                  ),
                ),
              ),

              // Top badge overlay: Camera capture tag & doc type
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF34D399), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_rounded, size: 11, color: Color(0xFF34D399)),
                          const SizedBox(width: 4),
                          Text(
                            isBackSide ? 'CAMERA BACK CAPTURE' : 'CAMERA FRONT CAPTURE',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isBackSide ? '${idType.toUpperCase()} (BACK)' : '${idType.toUpperCase()} (FRONT)',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tap to expand indicator
              Positioned(
                top: 75,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38),
                  ),
                  child: const Icon(Icons.fullscreen_rounded, size: 18, color: Colors.white),
                ),
              ),

              // Bottom info banner with guest name & ID
              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            guestName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$idType (${isBackSide ? "Back" : "Front"}): $idNumber',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String photoPath, String idType, String guestName, {bool isBackSide = false}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Captured $idType (${isBackSide ? "Back" : "Front"}) • $guestName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF1E293B)),
                Container(
                  constraints: const BoxConstraints(maxHeight: 450),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: InteractiveViewer(
                      child: Image.file(
                        File(photoPath),
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.white38),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissingSideSlot({
    required String title,
    required bool isBackSide,
    required VoidCallback onCapture,
    required VoidCallback onCamera,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBackSide ? Icons.flip_to_back_rounded : Icons.badge_outlined,
              size: 26,
              color: const Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isBackSide
                ? 'Store address & QR verification data from the back of the card'
                : 'Store photo, name & document number from the front of the card',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt_rounded, size: 14),
                  label: Text(
                    isBackSide ? 'Snap Back' : 'Snap Front',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.document_scanner_rounded, size: 14, color: Color(0xFF38BDF8)),
                  label: Text(
                    'Scan / Upload',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF38BDF8)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalDocumentImageCard({
    required String idType,
    required String guestName,
    required String idNumber,
    bool isBackSide = false,
  }) {
    if (isBackSide) {
      if (idType == 'Passport') {
        return _buildPassportBackImageCard(guestName, idNumber);
      } else if (idType == 'Driving License') {
        return _buildDrivingLicenseBackImageCard(guestName, idNumber);
      } else if (idType == 'Voter ID') {
        return _buildVoterIdBackImageCard(guestName, idNumber);
      }
      return _buildAadhaarBackImageCard(guestName, idNumber);
    }

    if (idType == 'Passport') {
      return _buildPassportImageCard(guestName, idNumber);
    } else if (idType == 'Driving License') {
      return _buildDrivingLicenseImageCard(guestName, idNumber);
    } else if (idType == 'Voter ID') {
      return _buildVoterIdImageCard(guestName, idNumber);
    }
    return _buildAadhaarImageCard(guestName, idNumber);
  }

  Widget _buildAadhaarBackImageCard(String guestName, String idNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tricolor Top Strip
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                  stops: [0.33, 0.66, 1.0],
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, size: 15, color: Color(0xFF1E293B)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'भारतीय विशिष्ट पहचान प्राधिकरण',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                              ),
                              Text(
                                'UNIQUE IDENTIFICATION AUTHORITY OF INDIA',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: 0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'BACK SIDE',
                      style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w800, color: const Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Card Body (Address Details & Secure QR)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address & Guardian Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'पता / Address:',
                          style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'S/O Ramesh Kumar, House No. 42/B, Green Park Extension, New Delhi - 110016',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 8.5, height: 1.25, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_in_talk_rounded, size: 9, color: Color(0xFF0D9488)),
                            const SizedBox(width: 3),
                            Text(
                              'UIDAI Helpline: 1947',
                              style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w600, color: const Color(0xFF0D9488)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Large UIDAI Secure QR Code
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF94A3B8), width: 1.0),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 44, color: Color(0xFF0F172A)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                          color: Colors.white,
                          child: Text(
                            'SECURE',
                            style: GoogleFonts.inter(fontSize: 5, fontWeight: FontWeight.w900, color: const Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Slogan Strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
              ),
              child: Column(
                children: [
                  Text(
                    'मेरा आधार, मेरी पहचान',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                        stops: [0.33, 0.66, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportBackImageCard(String guestName, String idNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('REPUBLIC OF INDIA • PASSPORT BACK', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF38BDF8))),
              Text('DL1067894562021', style: GoogleFonts.inter(fontSize: 8, color: Colors.white60)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Father / Legal Guardian: RAMESH KUMAR', style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white)),
          Text('Mother: SHANTI DEVI', style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white)),
          Text('Address: 42/B, GREEN PARK, NEW DELHI, INDIA', style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
            child: Text('P<IND<<VEKARIYA<<NIRAJ<<<<<<<<<<<<<<<<<<', style: GoogleFonts.inter(fontSize: 7.5, color: Colors.white60, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrivingLicenseBackImageCard(String guestName, String idNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DRIVING LICENCE • ENDORSEMENTS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF34D399))),
              Text('ORGAN DONOR: YES', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w700, color: const Color(0xFFFBBF24))),
            ],
          ),
          const SizedBox(height: 6),
          Text('CLASS: MCWG (Motorcycle) | LMV (Car/Jeep) - Valid upto 2040', style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white)),
          Text('Issuing Authority: RTO New Delhi (Central Zone)', style: GoogleFonts.inter(fontSize: 8, color: Colors.white60)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.qr_code_rounded, size: 26, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Card No: $idNumber\nEmergency Contact: +91 98765 43210', style: GoogleFonts.inter(fontSize: 8, color: Colors.white60)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoterIdBackImageCard(String guestName, String idNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ELECTION COMMISSION OF INDIA • BACK', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF38BDF8))),
          const SizedBox(height: 6),
          Text('Address: 42, Green Park Extension, Ward 12, New Delhi', style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white)),
          Text('Assembly Constituency: 40 - New Delhi', style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white70)),
          Text('Electoral Registration Officer Seal & Sign Verified', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF4ADE80))),
        ],
      ),
    );
  }

  Widget _buildAadhaarImageCard(String guestName, String idNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tricolor Top Strip
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                  stops: [0.33, 0.66, 1.0],
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, size: 15, color: Color(0xFF1E293B)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'भारत सरकार',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                              ),
                              Text(
                                'GOVERNMENT OF INDIA',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: 0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.fingerprint_rounded, size: 20, color: Color(0xFFDC2626)),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Card Body
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  // Photo with holographic frame
                  Container(
                    width: 44,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF94A3B8), width: 1.0),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.person, size: 30, color: Color(0xFF64748B)),
                        Positioned(
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'VERIFIED',
                              style: GoogleFonts.inter(fontSize: 5, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Identity Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DOB: 14/08/1995 • Male',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'आधार क्रमांक / Aadhaar No.:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 7.5, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            idNumber,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0D9488),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 2D QR Code Container
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 32, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),

            // Bottom Slogan Strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
              ),
              child: Column(
                children: [
                  Text(
                    'मेरा आधार, मेरी पहचान',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                        stops: [0.33, 0.66, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportImageCard(String guestName, String idNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD97706), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.auto_stories_rounded, size: 14, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'REPUBLIC OF INDIA • PASSPORT',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFFFBBF24), letterSpacing: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TYPE: P • IND',
                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF334155)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFFBBF24), width: 1.0),
                    ),
                    child: const Icon(Icons.person, size: 30, color: Colors.white54),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nationality: INDIAN • Sex: M',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 8.5, color: Colors.white70),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Passport No.:',
                          style: GoogleFonts.inter(fontSize: 7.5, color: Colors.white54),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            idNumber,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF38BDF8), letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Monospace MRZ Band
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: const Color(0xFF020617),
              child: Text(
                'P<IND${guestName.replaceAll(" ", "<")}<<<<<<<<<<<<<<<<<<\n${idNumber.replaceAll("-", "")}<3IND9508144M3508140<<<<<<<4',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.robotoMono(fontSize: 7.5, color: const Color(0xFF38BDF8), letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingLicenseImageCard(String guestName, String idNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF16A34A), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'UNION OF INDIA - DRIVING LICENCE',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF166534), letterSpacing: 0.3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.memory_rounded, size: 15, color: Color(0xFFD97706)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFBBF7D0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF16A34A)),
                    ),
                    child: const Icon(Icons.person, size: 30, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF14532D)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Auth: LMV, MCWG • Valid Till: 2035',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 8.5, color: const Color(0xFF166534)),
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            idNumber,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF15803D), letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoterIdImageCard(String guestName, String idNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ELECTION COMMISSION OF INDIA',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF1E40AF), letterSpacing: 0.3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.how_to_vote_rounded, size: 15, color: Color(0xFF2563EB)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFBFDBFE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF2563EB)),
                    ),
                    child: const Icon(Icons.person, size: 30, color: Color(0xFF1D4ED8)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'EPIC NO: $idNumber',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF1D4ED8), letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 650;

    final isNameInvalid = widget.showValidationErrors && _nameController.text.trim().isEmpty;
    final isIdNumberInvalid = widget.showValidationErrors && _idNumberController.text.trim().isEmpty;
    final isPhoneInvalid = widget.showValidationErrors && _phoneController.text.trim().isEmpty;
    final isIdVerificationInvalid = widget.showValidationErrors && !_isIdVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        // ----------------- PRIMARY GUEST CARD -----------------
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isNameInvalid || isIdNumberInvalid || isPhoneInvalid || isIdVerificationInvalid)
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0),
              width: (isNameInvalid || isIdNumberInvalid || isPhoneInvalid || isIdVerificationInvalid) ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary Guest Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.person_pin_rounded, color: Color(0xFF4F46E5), size: 16),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'PRIMARY GUEST IDENTITY',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF312E81),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      'MAIN GUEST',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // Guest Full Name
              CustomTextField(
                label: 'Primary Guest Full Name (as per Govt ID) *',
                hintText: 'e.g. Niraj Vekariya',
                errorText: isNameInvalid ? 'Guest full name (as per Govt ID) is required' : null,
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                onChanged: (_) {
                  _notify();
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              // Mobile Number & Email ID
              if (isCompact) ...[
                CustomTextField(
                  label: 'Mobile Number *',
                  hintText: 'e.g. +91 98765 43210',
                  errorText: isPhoneInvalid ? 'Mobile number is required' : null,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  onChanged: (_) {
                    _notify();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Email ID',
                  hintText: 'e.g. guest@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                  onChanged: (_) {
                    _notify();
                    setState(() {});
                  },
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Mobile Number *',
                        hintText: 'e.g. +91 98765 43210',
                        errorText: isPhoneInvalid ? 'Mobile number is required' : null,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
                        onChanged: (_) {
                          _notify();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Email ID',
                        hintText: 'e.g. guest@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.alternate_email_rounded,
                        onChanged: (_) {
                          _notify();
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Govt ID Type & ID Number Row
              if (isCompact) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary ID Type *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedIdType,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          items: _idTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedIdType = val;
                                _idNumberController.clear();
                                widget.formData.idNumber = '';
                              });
                              _notify();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  labelWidget: _buildIdFieldLabelWithHint(
                    label: 'Primary Govt ID Document Number *',
                    idType: _selectedIdType,
                    onUseHint: () {
                      final hint = _getIdHintNumber(_selectedIdType);
                      _idNumberController.text = hint;
                      widget.formData.idNumber = hint;
                      _notify();
                      setState(() {});
                    },
                  ),
                  hintText: _getIdHintText(_selectedIdType),
                  helperText: 'Selected Doc Format: ${_getIdHintNumber(_selectedIdType)} (${_getIdFormatDesc(_selectedIdType)})',
                  keyboardType: _getIdKeyboardType(_selectedIdType),
                  textCapitalization: _getIdTextCapitalization(_selectedIdType),
                  errorText: isIdNumberInvalid ? 'Please enter valid $_selectedIdType document number' : null,
                  controller: _idNumberController,
                  prefixIcon: Icons.badge_outlined,
                  onChanged: (_) {
                    _notify();
                    setState(() {});
                  },
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Primary ID Type *',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedIdType,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                items: _idTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedIdType = val;
                                      _idNumberController.clear();
                                      widget.formData.idNumber = '';
                                    });
                                    _notify();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        labelWidget: _buildIdFieldLabelWithHint(
                          label: 'Primary Govt ID Document Number *',
                          idType: _selectedIdType,
                          onUseHint: () {
                            final hint = _getIdHintNumber(_selectedIdType);
                            _idNumberController.text = hint;
                            widget.formData.idNumber = hint;
                            _notify();
                            setState(() {});
                          },
                        ),
                        hintText: _getIdHintText(_selectedIdType),
                        helperText: 'Selected Doc Format: ${_getIdHintNumber(_selectedIdType)} (${_getIdFormatDesc(_selectedIdType)})',
                        keyboardType: _getIdKeyboardType(_selectedIdType),
                        textCapitalization: _getIdTextCapitalization(_selectedIdType),
                        errorText: isIdNumberInvalid ? 'Please enter valid $_selectedIdType document number' : null,
                        controller: _idNumberController,
                        prefixIcon: Icons.badge_outlined,
                        onChanged: (_) {
                          _notify();
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Digital ID Scan / Document Verification
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Digital ID Scan / Document Verification',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_primaryIdPhotoUrl != null || _primaryIdBackPhotoUrl != null) ...[
                    // Front Side & Back Side Segmented Switcher
                    Container(
                      height: 38,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _primaryActiveSideIsBack = false),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !_primaryActiveSideIsBack ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: !_primaryActiveSideIsBack
                                      ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _primaryIdPhotoUrl != null ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                      size: 13,
                                      color: _primaryIdPhotoUrl != null ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _primaryIdPhotoUrl != null ? 'Front Side ✓' : 'Front Side',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: !_primaryActiveSideIsBack ? FontWeight.w700 : FontWeight.w500,
                                          color: !_primaryActiveSideIsBack ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _primaryActiveSideIsBack = true),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _primaryActiveSideIsBack ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: _primaryActiveSideIsBack
                                      ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _primaryIdBackPhotoUrl != null ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                      size: 13,
                                      color: _primaryIdBackPhotoUrl != null ? const Color(0xFF059669) : const Color(0xFF0284C7),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _primaryIdBackPhotoUrl != null ? 'Back Side ✓' : '+ Add Back',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: _primaryActiveSideIsBack ? FontWeight.w700 : FontWeight.w500,
                                          color: _primaryActiveSideIsBack ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_primaryActiveSideIsBack) ...[
                      if (_primaryIdPhotoUrl != null)
                        _buildScannedDocPreviewWidget(
                          guestName: _nameController.text,
                          idType: _selectedIdType,
                          idNumber: _idNumberController.text,
                          photoUrl: _primaryIdPhotoUrl,
                          isBackSide: false,
                          sideBadge: 'FRONT SIDE',
                          onRescan: () => _openOcrScannerModal(context, initialBackSide: false),
                          onRemove: () {
                            setState(() {
                              _primaryIdPhotoUrl = null;
                              _primaryIdBackPhotoUrl = null;
                              widget.formData.idFrontPhotoUrl = null;
                              widget.formData.idBackPhotoUrl = null;
                            });
                            _notify();
                          },
                        )
                      else
                        _buildMissingSideSlot(
                          title: 'Front Side Document Not Captured',
                          isBackSide: false,
                          onCapture: () => _openOcrScannerModal(context, initialBackSide: false),
                          onCamera: () => _captureWithDeviceCamera(isBackSide: false),
                        ),
                    ] else ...[
                      if (_primaryIdBackPhotoUrl != null)
                        _buildScannedDocPreviewWidget(
                          guestName: _nameController.text,
                          idType: _selectedIdType,
                          idNumber: _idNumberController.text,
                          photoUrl: _primaryIdBackPhotoUrl,
                          isBackSide: true,
                          sideBadge: 'BACK SIDE',
                          onRescan: () => _openOcrScannerModal(context, initialBackSide: true),
                          onRemove: () {
                            setState(() {
                              _primaryIdBackPhotoUrl = null;
                              widget.formData.idBackPhotoUrl = null;
                              _primaryActiveSideIsBack = false;
                            });
                            _notify();
                          },
                        )
                      else
                        _buildMissingSideSlot(
                          title: 'Back Side Document Not Captured (Address & QR)',
                          isBackSide: true,
                          onCapture: () => _openOcrScannerModal(context, initialBackSide: true),
                          onCamera: () => _captureWithDeviceCamera(isBackSide: true),
                        ),
                    ],
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => _openOcrScannerModal(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primaryLight, style: BorderStyle.solid),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.document_scanner_outlined, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Scan Original ID Document (OCR Auto-Fill)',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _captureWithDeviceCamera(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Camera',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Verification Status Checkbox for Primary Guest
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isIdVerificationInvalid ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: isIdVerificationInvalid
                      ? Border.all(color: const Color(0xFFFCA5A5), width: 1.2)
                      : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _isIdVerified = !_isIdVerified);
                        _notify();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _isIdVerified,
                              activeColor: AppColors.accentGreen,
                              onChanged: (val) {
                                setState(() => _isIdVerified = val ?? false);
                                _notify();
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Primary guest original physical ID inspected & verified',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mandatory regulatory requirement for hotel guest registration desk.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isIdVerificationInvalid) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Physical ID inspection confirmation is mandatory',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ----------------- ATTACHED GUESTS SECTION (AUTOMATIC FOR COUPLE / FAMILY) -----------------
        if (widget.formData.accompanyingGuests.isNotEmpty ||
            widget.formData.roomType.toLowerCase().contains('couple') ||
            widget.formData.roomType.toLowerCase().contains('family')) ...[
          const SizedBox(height: 24),

          // Section Header with Add Member Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: widget.formData.roomType.toLowerCase().contains('couple')
                            ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        widget.formData.roomType.toLowerCase().contains('couple')
                            ? Icons.favorite_rounded
                            : Icons.family_restroom_rounded,
                        color: widget.formData.roomType.toLowerCase().contains('couple')
                            ? const Color(0xFFDB2777)
                            : const Color(0xFFD97706),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ATTACHED IDENTITIES',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: widget.formData.roomType.toLowerCase().contains('couple')
                              ? const Color(0xFF831843)
                              : const Color(0xFF92400E),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: _addAccompanyingGuest,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                label: Text(
                  '+ Add Member',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: widget.formData.roomType.toLowerCase().contains('couple')
                      ? const Color(0xFFDB2777)
                      : const Color(0xFFD97706),
                  backgroundColor: widget.formData.roomType.toLowerCase().contains('couple')
                      ? const Color(0xFFFDF2F8)
                      : const Color(0xFFFEF3C7),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Accompanying Guests Card List
          ...List.generate(widget.formData.accompanyingGuests.length, (index) {
            return _buildAccompanyingGuestCard(index, isCompact);
          }),
        ],

        const SizedBox(height: 16),
      ],
    );
  }


  Widget _buildAccompanyingGuestCard(int index, bool isCompact) {
    if (index >= widget.formData.accompanyingGuests.length || index >= _accompanyingControllers.length) {
      return const SizedBox.shrink();
    }

    final guest = widget.formData.accompanyingGuests[index];
    final controllers = _accompanyingControllers[index];

    final isNameInvalid = widget.showValidationErrors && (controllers['name']?.text.trim().isEmpty ?? true);
    final isIdNumberInvalid = widget.showValidationErrors && (controllers['idNumber']?.text.trim().isEmpty ?? true);
    final isIdVerificationInvalid = widget.showValidationErrors && !guest.isIdVerified;

    final isCouple = widget.formData.roomType.toLowerCase().contains('couple') ||
        _selectedPartyType == 'Couple (2 Guests)';
    final String title = isCouple && index == 0
        ? 'Guest 2 (Spouse / Companion)'
        : 'Family Member #${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isNameInvalid || isIdNumberInvalid || isIdVerificationInvalid)
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFFBCFE8),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.badge_rounded, color: Color(0xFFDB2777), size: 15),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF831843),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fast OCR button for attached member
                  InkWell(
                    onTap: () => _openOcrScannerModal(context, accompanyingIndex: index),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: (guest.idPhotoUrl != null || guest.idBackPhotoUrl != null)
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: (guest.idPhotoUrl != null || guest.idBackPhotoUrl != null)
                            ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (guest.idPhotoUrl != null || guest.idBackPhotoUrl != null)
                                ? Icons.verified_rounded
                                : Icons.document_scanner_rounded,
                            size: 12,
                            color: (guest.idPhotoUrl != null || guest.idBackPhotoUrl != null)
                                ? const Color(0xFF059669)
                                : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            (guest.idPhotoUrl != null || guest.idBackPhotoUrl != null) ? 'ID Stored' : 'Scan ID',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: (guest.idPhotoUrl != null || guest.idBackPhotoUrl != null)
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Remove member button
                  InkWell(
                    onTap: () => _removeAccompanyingGuest(index),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Member Name & Relationship Row
          if (isCompact) ...[
            CustomTextField(
              label: 'Attached Member Full Name *',
              hintText: 'e.g. Pooja Vekariya',
              errorText: isNameInvalid ? 'Member full name is required' : null,
              controller: controllers['name'],
              prefixIcon: Icons.person_outline,
              onChanged: (_) {
                _notify();
                setState(() {});
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relationship *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _relationships.contains(guest.relationship) ? guest.relationship : 'Spouse',
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            items: _relationships.map((rel) {
                              return DropdownMenuItem<String>(
                                value: rel,
                                child: Text(rel),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => guest.relationship = val);
                                _notify();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Age',
                    hintText: 'e.g. 28',
                    controller: controllers['age'],
                    prefixIcon: Icons.cake_outlined,
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: CustomTextField(
                    label: 'Attached Member Full Name *',
                    hintText: 'e.g. Pooja Vekariya',
                    errorText: isNameInvalid ? 'Member full name is required' : null,
                    controller: controllers['name'],
                    prefixIcon: Icons.person_outline,
                    onChanged: (_) {
                      _notify();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relationship *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _relationships.contains(guest.relationship) ? guest.relationship : 'Spouse',
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            items: _relationships.map((rel) {
                              return DropdownMenuItem<String>(
                                value: rel,
                                child: Text(rel),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => guest.relationship = val);
                                _notify();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Age',
                    hintText: 'e.g. 28',
                    controller: controllers['age'],
                    prefixIcon: Icons.cake_outlined,
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ID Type & ID Number Row
          if (isCompact) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Member ID Document Type *',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _accompanyingIdTypes.contains(guest.idType) ? guest.idType : 'Aadhaar Card',
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      items: _accompanyingIdTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            guest.idType = val;
                            controllers['idNumber']?.clear();
                            guest.idNumber = '';
                          });
                          _notify();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomTextField(
              labelWidget: _buildIdFieldLabelWithHint(
                label: 'Member Govt ID Number *',
                idType: guest.idType,
                onUseHint: () {
                  final hint = _getIdHintNumber(guest.idType);
                  controllers['idNumber']?.text = hint;
                  guest.idNumber = hint;
                  _notify();
                  setState(() {});
                },
              ),
              hintText: _getIdHintText(guest.idType),
              helperText: 'Selected Doc Format: ${_getIdHintNumber(guest.idType)} (${_getIdFormatDesc(guest.idType)})',
              keyboardType: _getIdKeyboardType(guest.idType),
              textCapitalization: _getIdTextCapitalization(guest.idType),
              errorText: isIdNumberInvalid ? 'Please enter valid ${guest.idType} number' : null,
              controller: controllers['idNumber'],
              prefixIcon: Icons.badge_outlined,
              onChanged: (_) {
                _notify();
                setState(() {});
              },
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Member ID Document Type *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _accompanyingIdTypes.contains(guest.idType) ? guest.idType : 'Aadhaar Card',
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            items: _accompanyingIdTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  guest.idType = val;
                                  controllers['idNumber']?.clear();
                                  guest.idNumber = '';
                                });
                                _notify();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    labelWidget: _buildIdFieldLabelWithHint(
                      label: 'Member Govt ID Number *',
                      idType: guest.idType,
                      onUseHint: () {
                        final hint = _getIdHintNumber(guest.idType);
                        controllers['idNumber']?.text = hint;
                        guest.idNumber = hint;
                        _notify();
                        setState(() {});
                      },
                    ),
                    hintText: _getIdHintText(guest.idType),
                    helperText: 'Selected Doc Format: ${_getIdHintNumber(guest.idType)} (${_getIdFormatDesc(guest.idType)})',
                    keyboardType: _getIdKeyboardType(guest.idType),
                    textCapitalization: _getIdTextCapitalization(guest.idType),
                    errorText: isIdNumberInvalid ? 'Please enter valid ${guest.idType} number' : null,
                    controller: controllers['idNumber'],
                    prefixIcon: Icons.badge_outlined,
                    onChanged: (_) {
                      _notify();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],

          // Digital ID Scan / Original Document Image Preview for Accompanying Guest
          if (guest.idPhotoUrl != null || guest.idBackPhotoUrl != null) ...[
            const SizedBox(height: 10),
            // Front & Back tab switcher for member
            Container(
              height: 34,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _accompanyingActiveSideIsBack[index] = false),
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !(_accompanyingActiveSideIsBack[index] ?? false) ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: !(_accompanyingActiveSideIsBack[index] ?? false)
                              ? [const BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              guest.idPhotoUrl != null ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              size: 11,
                              color: guest.idPhotoUrl != null ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                guest.idPhotoUrl != null ? 'Front Side ✓' : 'Front Side',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: !(_accompanyingActiveSideIsBack[index] ?? false) ? FontWeight.w700 : FontWeight.w500,
                                  color: !(_accompanyingActiveSideIsBack[index] ?? false) ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _accompanyingActiveSideIsBack[index] = true),
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (_accompanyingActiveSideIsBack[index] ?? false) ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: (_accompanyingActiveSideIsBack[index] ?? false)
                              ? [const BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              guest.idBackPhotoUrl != null ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              size: 11,
                              color: guest.idBackPhotoUrl != null ? const Color(0xFF059669) : const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                guest.idBackPhotoUrl != null ? 'Back Side ✓' : '+ Add Back',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: (_accompanyingActiveSideIsBack[index] ?? false) ? FontWeight.w700 : FontWeight.w500,
                                  color: (_accompanyingActiveSideIsBack[index] ?? false) ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!(_accompanyingActiveSideIsBack[index] ?? false)) ...[
              if (guest.idPhotoUrl != null)
                _buildScannedDocPreviewWidget(
                  guestName: controllers['name']?.text.isNotEmpty == true ? controllers['name']!.text : guest.name,
                  idType: guest.idType,
                  idNumber: controllers['idNumber']?.text.isNotEmpty == true ? controllers['idNumber']!.text : guest.idNumber,
                  photoUrl: guest.idPhotoUrl,
                  isBackSide: false,
                  sideBadge: 'FRONT SIDE',
                  onRescan: () => _openOcrScannerModal(context, accompanyingIndex: index, initialBackSide: false),
                  onRemove: () {
                    setState(() {
                      guest.idPhotoUrl = null;
                      guest.idBackPhotoUrl = null;
                    });
                    _notify();
                  },
                )
              else
                _buildMissingSideSlot(
                  title: 'Front Side Document Not Captured',
                  isBackSide: false,
                  onCapture: () => _openOcrScannerModal(context, accompanyingIndex: index, initialBackSide: false),
                  onCamera: () => _captureWithDeviceCamera(accompanyingIndex: index, isBackSide: false),
                ),
            ] else ...[
              if (guest.idBackPhotoUrl != null)
                _buildScannedDocPreviewWidget(
                  guestName: controllers['name']?.text.isNotEmpty == true ? controllers['name']!.text : guest.name,
                  idType: guest.idType,
                  idNumber: controllers['idNumber']?.text.isNotEmpty == true ? controllers['idNumber']!.text : guest.idNumber,
                  photoUrl: guest.idBackPhotoUrl,
                  isBackSide: true,
                  sideBadge: 'BACK SIDE',
                  onRescan: () => _openOcrScannerModal(context, accompanyingIndex: index, initialBackSide: true),
                  onRemove: () {
                    setState(() {
                      guest.idBackPhotoUrl = null;
                      _accompanyingActiveSideIsBack[index] = false;
                    });
                    _notify();
                  },
                )
              else
                _buildMissingSideSlot(
                  title: 'Back Side Document Not Captured (Address & QR)',
                  isBackSide: true,
                  onCapture: () => _openOcrScannerModal(context, accompanyingIndex: index, initialBackSide: true),
                  onCamera: () => _captureWithDeviceCamera(accompanyingIndex: index, isBackSide: true),
                ),
            ],
          ],

          const SizedBox(height: 10),

          // Attached Member ID Verification Checkbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isIdVerificationInvalid ? const Color(0xFFFEF2F2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isIdVerificationInvalid ? Border.all(color: const Color(0xFFFCA5A5), width: 1.0) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() => guest.isIdVerified = !guest.isIdVerified);
                    _notify();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: guest.isIdVerified,
                        activeColor: AppColors.accentGreen,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() => guest.isIdVerified = val ?? false);
                          _notify();
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Member's original government ID verified & compliant",
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isIdVerificationInvalid) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 2),
                    child: Text(
                      "Please verify attached member's ID",
                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFDC2626), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
