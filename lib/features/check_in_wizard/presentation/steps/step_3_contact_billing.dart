import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/check_in_form_data.dart';

class Step3ContactBilling extends StatefulWidget {
  final CheckInFormData formData;
  final ValueChanged<CheckInFormData> onDataChanged;
  final bool showValidationErrors;

  const Step3ContactBilling({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.showValidationErrors = false,
  });

  @override
  State<Step3ContactBilling> createState() => _Step3ContactBillingState();
}

class _Step3ContactBillingState extends State<Step3ContactBilling> {
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.formData.contactPhone);
    _emailController = TextEditingController(text: widget.formData.email);
    _addressController = TextEditingController(text: widget.formData.residentialAddress);
    _cityController = TextEditingController(text: widget.formData.city);
    _stateController = TextEditingController(text: widget.formData.state);
    _pincodeController = TextEditingController(text: widget.formData.pincode);
  }

  @override
  void didUpdateWidget(covariant Step3ContactBilling oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formData.contactPhone != _phoneController.text) {
      _phoneController.text = widget.formData.contactPhone;
    }
    if (widget.formData.email != _emailController.text) {
      _emailController.text = widget.formData.email;
    }
    if (widget.formData.residentialAddress != _addressController.text) {
      _addressController.text = widget.formData.residentialAddress;
    }
    if (widget.formData.city != _cityController.text) {
      _cityController.text = widget.formData.city;
    }
    if (widget.formData.state != _stateController.text) {
      _stateController.text = widget.formData.state;
    }
    if (widget.formData.pincode != _pincodeController.text) {
      _pincodeController.text = widget.formData.pincode;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _notify() {
    final updated = widget.formData.copy();
    updated.contactPhone = _phoneController.text;
    updated.email = _emailController.text;
    updated.residentialAddress = _addressController.text;
    updated.city = _cityController.text;
    updated.state = _stateController.text;
    updated.pincode = _pincodeController.text;
    widget.onDataChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 650;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone & Email Row (or column on compact)
        if (isCompact) ...[
          CustomTextField(
            label: 'Contact Phone Number *',
            hintText: 'e.g. +91 98765 43210',
            errorText: widget.showValidationErrors && _phoneController.text.trim().isEmpty
                ? 'Contact phone number is required'
                : null,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            onChanged: (_) {
              _notify();
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Email Address *',
            hintText: 'e.g. niraj.v@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            onChanged: (_) => _notify(),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Contact Phone Number *',
                  hintText: 'e.g. +91 98765 43210',
                  errorText: widget.showValidationErrors && _phoneController.text.trim().isEmpty
                      ? 'Contact phone number is required'
                      : null,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  onChanged: (_) {
                    _notify();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CustomTextField(
                  label: 'Email Address *',
                  hintText: 'e.g. niraj.v@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // Residential Address
        CustomTextField(
          label: 'Residential / Permanent Address',
          hintText: 'House/Flat #, Building Name, Street',
          controller: _addressController,
          prefixIcon: Icons.home_outlined,
          onChanged: (_) => _notify(),
        ),

        const SizedBox(height: 14),

        // City, State, PIN
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'City',
                hintText: 'e.g. Surat',
                controller: _cityController,
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomTextField(
                label: 'State',
                hintText: 'e.g. Gujarat',
                controller: _stateController,
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomTextField(
                label: 'Pincode',
                hintText: 'e.g. 395007',
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _notify(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
