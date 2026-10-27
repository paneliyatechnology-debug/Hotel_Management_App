import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/guest_folio_model.dart';
import 'package:my_own_pms_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_own_pms_system/features/folios/presentation/widgets/checkout_settlement_dialog.dart';

void main() {
  Widget buildTestWidget(GuestFolioModel folio) {
    DashboardRepository(initialFolios: [folio]);
    return MaterialApp(
      home: BlocProvider(
        create: (_) => DashboardBloc(repository: DashboardRepository()),
        child: CheckoutSettlementDialog(folio: folio),
      ),
    );
  }

  testWidgets('Discount field is removed from checkout settlement dialog', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final folio = GuestFolioModel(
      id: 'BK-TEST-101',
      guestName: 'abc',
      assignedRoom: '101',
      roomType: 'Deluxe',
      checkInDate: DateTime.now().subtract(const Duration(days: 1)),
      checkOutDate: DateTime.now(),
      status: FolioStatus.inHouse,
      roomRatePerNight: 4000.0,
      totalAmount: 4000.0,
      advancePaid: 0.0,
      roomCharges: 4000.0,
      phone: '9408036136',
      email: 'abc@test.com',
      idType: 'AADHAAR',
      idNumber: '123456789012',
    );

    await tester.pumpWidget(buildTestWidget(folio));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify dialog header
    expect(find.textContaining('Check-out'), findsOneWidget);

    // Verify Extra charges is rendered
    expect(find.text('Extra charges (₹)'), findsOneWidget);

    // Verify Discount field is not shown
    expect(find.text('Discount (₹)'), findsNothing);
    expect(find.text('Discount'), findsNothing);
  });
}
