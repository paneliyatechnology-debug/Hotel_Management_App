import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class ReceptionistToolDialogs {
  ReceptionistToolDialogs._();

  /// 1. Early Check-in & Late Checkout Fee Calculator
  static void showEarlyLateCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String calculationType = 'Late Checkout';
        double roomRate = 5000;
        int hours = 2;

        return StatefulBuilder(
          builder: (modalCtx, setState) {
            double calculatedFee = 0;
            String policyExplanation = '';

            if (calculationType == 'Late Checkout') {
              if (hours <= 1) {
                calculatedFee = 0;
                policyExplanation = 'Grace period: Complementary (Subject to availability)';
              } else if (hours <= 3) {
                calculatedFee = (hours * 500);
                policyExplanation = 'Standard late fee: ₹500 per hour until 02:00 PM';
              } else if (hours <= 6) {
                calculatedFee = roomRate * 0.5;
                policyExplanation = 'Half-day charge: 50% of nightly tariff until 06:00 PM';
              } else {
                calculatedFee = roomRate;
                policyExplanation = 'Full night charge: Checkout after 06:00 PM billed as full day';
              }
            } else {
              // Early check-in
              if (hours <= 2) {
                calculatedFee = 0;
                policyExplanation = 'Standard early check-in (12 PM - 2 PM): Complementary if room ready';
              } else if (hours <= 5) {
                calculatedFee = roomRate * 0.35;
                policyExplanation = 'Early morning arrival (09:00 AM - 12:00 PM): 35% of room rate';
              } else {
                calculatedFee = roomRate * 0.75;
                policyExplanation = 'Overnight / dawn arrival (Before 09:00 AM): 75% of full night tariff';
              }
            }

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Early / Late Fee Calculator', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('Reception front desk billing policy guide', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Type Toggle
                    Row(
                      children: ['Late Checkout', 'Early Check-in'].map((type) {
                        final isSel = calculationType == type;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSel ? AppColors.primary : const Color(0xFFF1F5F9),
                                foregroundColor: isSel ? Colors.white : AppColors.textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => setState(() => calculationType = type),
                              child: Text(type, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Nightly rate selector
                    Text('Nightly Room Rate (Tariff)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [2500, 4200, 5000, 7500, 12000].map((rate) {
                        final isSel = roomRate == rate;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: InkWell(
                              onTap: () => setState(() => roomRate = rate.toDouble()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primarySurface : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSel ? AppColors.primary : const Color(0xFFE2E8F0)),
                                ),
                                alignment: Alignment.center,
                                child: Text('₹$rate', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: isSel ? FontWeight.w800 : FontWeight.w500, color: isSel ? AppColors.primaryDark : AppColors.textSecondary)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Hours duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Extension Hours: $hours Hours', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          calculationType == 'Late Checkout' ? 'Std checkout: 11:00 AM' : 'Std check-in: 02:00 PM',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Slider(
                      value: hours.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      activeColor: AppColors.primary,
                      label: '$hours hrs',
                      onChanged: (val) => setState(() => hours = val.toInt()),
                    ),
                    const SizedBox(height: 12),

                    // Result card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('APPROVED SURCHARGE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF15803D), letterSpacing: 0.5)),
                              ),
                              const SizedBox(width: 8),
                              Text(CurrencyFormatter.format(calculatedFee), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF14532D))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(policyExplanation, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF166534))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
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

  /// 2. Tariff & GST Tax Calculator
  static void showGstCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final controller = TextEditingController(text: '4500');
        double tariff = 4500;

        return StatefulBuilder(
          builder: (modalCtx, setState) {
            double gstRate = tariff > 7500 ? 0.18 : (tariff > 1000 ? 0.12 : 0.0);
            double cgst = (tariff * (gstRate / 2));
            double sgst = (tariff * (gstRate / 2));
            double totalTax = cgst + sgst;
            double grandTotal = tariff + totalTax;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Indian Hospitality GST Calculator', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('Ministry of Finance Hotel Tax Slabs', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Text('Declared Room Tariff / Night (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (val) {
                        final p = double.tryParse(val) ?? 0;
                        setState(() => tariff = p);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Tax breakdown
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _rowLine('Base Room Tariff', CurrencyFormatter.format(tariff)),
                          _rowLine('GST Slab', '${(gstRate * 100).toInt()}% GST (${tariff > 7500 ? "Luxury >₹7.5k" : tariff > 1000 ? "Standard ₹1k-₹7.5k" : "Exempt ≤₹1k"})'),
                          _rowLine('CGST (${(gstRate * 50).toInt()}%)', CurrencyFormatter.format(cgst)),
                          _rowLine('SGST (${(gstRate * 50).toInt()}%)', CurrencyFormatter.format(sgst)),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _rowLine('Total Tax', CurrencyFormatter.format(totalTax), color: const Color(0xFFD97706), isBold: true),
                          _rowLine('Total Guest Payable', CurrencyFormatter.format(grandTotal), color: AppColors.primaryDark, isBold: true, fontSize: 14),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Close Calculator', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
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

  /// 3. Wake-Up Call Register Modal
  static void showWakeUpCallDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sampleCalls = [
          {'room': 'Room #03', 'guest': 'Vikram Mehta', 'time': '06:00 AM', 'status': 'Pending'},
          {'room': 'Room #12', 'guest': 'Ananya Sharma', 'time': '07:15 AM', 'status': 'Pending'},
          {'room': 'Room #07', 'guest': 'Rajesh Gupta', 'time': '05:30 AM', 'status': 'Completed'},
        ];

        return StatefulBuilder(
          builder: (modalCtx, setState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.alarm_rounded, color: Color(0xFF4F46E5), size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Wake-Up Call Register', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                                    Text('Scheduled morning telephone reminders', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Wake-up call request queued for Room #01 at 06:30 AM')),
                            );
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: Text('Add', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ...sampleCalls.map((c) {
                      final isDone = c['status'] == 'Completed';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.alarm_on_rounded, size: 18, color: isDone ? const Color(0xFF10B981) : const Color(0xFF4F46E5)),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${c['room']} • ${c['guest']}', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                    Text('Time: ${c['time']} • Operator Direct Call', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c['status']!,
                                style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: isDone ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 4. Lost & Found Register Modal
  static void showLostAndFoundDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final items = [
          {'item': 'Apple AirPods Pro', 'room': 'Room 14 (Floor 3)', 'date': '24 Sep 2026', 'status': 'Vault Safe #2'},
          {'item': 'Black Leather Wallet', 'room': 'Lobby Coffee Lounge', 'date': '23 Sep 2026', 'status': 'Vault Safe #1'},
          {'item': 'Titan Wristwatch', 'room': 'Room 06 (Floor 1)', 'date': '21 Sep 2026', 'status': 'Returned to Guest'},
        ];

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFD97706), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lost & Found Log', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('Housekeeping turns & lobby recoveries', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item logged to Front Desk Safe Vault.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 0,
                    ),
                    child: Text('Log Item', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...items.map((it) {
                final isReturned = it['status']!.contains('Returned');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it['item']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${it['room']} • Found on ${it['date']}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isReturned ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          it['status']!,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isReturned ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// 5. Master Keycard & RFID Encoder Dialog
  static void showMasterKeycardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.nfc_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('RFID Master Keycard Tool', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Encoder Status: Hardware Connected (USB Port 2)', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF15803D), fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _rowLine('Active Master Keys', '2 Cards (Duty Mgr & HK)'),
                  _rowLine('Encoder Frequency', '13.56 MHz Mifare Classic'),
                  _rowLine('Reader Signal', 'Optimal (98%)'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.key_rounded, color: AppColors.primary),
              title: Text('Encode Supervisor Master Key', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('Allows full emergency access to all floors', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Place RFID blank card on USB reader to complete encoding...')),
                );
              },
            ),
            const Divider(height: 8),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFFD97706)),
              title: Text('Wipe / Format Keycard', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('Erase guest door lock encoding from recycled card', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Keycard wiped and returned to blank pool.')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// 6. Night Audit & EOD Checklist Modal
  static void showNightAuditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final checklist = [
          {'title': 'All In-House Folios Reconciled', 'done': true},
          {'title': 'Day Departures Checked Out', 'done': true},
          {'title': 'Room Service & POS Invoices Settled', 'done': true},
          {'title': 'Police Form-C Registers Uploaded', 'done': true},
          {'title': 'Front Desk Cash Drawer Balanced', 'done': true},
          {'title': 'Roll Business Date to Tomorrow', 'done': false},
        ];

        return StatefulBuilder(
          builder: (modalCtx, setState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.nightlight_round, color: Color(0xFF1E293B), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Night Audit & Day-End Close', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('Audit checklist & post midnight room tariffs', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    ...checklist.map((item) {
                      final isDone = item['done'] as bool;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 20, color: isDone ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: isDone ? FontWeight.w600 : FontWeight.w500, color: isDone ? AppColors.textPrimary : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Night audit sequence executed. Room tariffs posted for active stays.')),
                          );
                        },
                        child: Text('Run Night Audit & Roll Date', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
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

  /// 7. Shift Handover & Cash Till Reconciliation
  static void showShiftHandoverDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final notesController = TextEditingController(text: 'Room 03 requested early morning airport taxi at 6 AM. Keycard KC-101 re-encoded.');

        return Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.sync_alt_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shift Handover & Reconciliation', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('Morning Shift (07:00 AM – 03:30 PM)', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Till Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _rowLine('Opening Cash Float', '₹5,000.00'),
                      _rowLine('Cash Payments Collected', '+₹8,000.00', color: const Color(0xFF10B981)),
                      _rowLine('UPI / Digital Payments', '₹18,500.00'),
                      _rowLine('Card POS Settlements', '₹15,000.00'),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      _rowLine('Closing Physical Cash in Till', '₹13,000.00', isBold: true, color: AppColors.primaryDark, fontSize: 13.5),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text('Handover Notes for Evening Receptionist', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 12.5),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shift handover registered. Drawer verified at ₹13,000.')),
                      );
                    },
                    child: Text('Complete Handover & Sign Off', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _rowLine(String label, String value, {Color? color, bool isBold = false, double fontSize = 12}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
