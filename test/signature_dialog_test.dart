import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/features/check_in_wizard/presentation/widgets/signature_pad_widget.dart';

void main() {
  testWidgets('Signature popup flow: Add Signature button -> Popup -> Draw -> Done -> Shows on screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    List<Offset?> capturedSignature = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SignaturePadWidget(
              signerName: 'Niraj Vekariya',
              title: 'Main Guest Signature',
              initialPoints: const [],
              onSignatureChanged: (points) {
                capturedSignature = List.from(points);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State: Empty signature with "Required" badge & "Add Signature" button
    expect(find.text('Main Guest Signature'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(find.byKey(const ValueKey('add_signature_btn')), findsOneWidget);
    expect(find.text('Add Signature'), findsOneWidget);
    expect(find.text('Touch & drag finger here to sign'), findsOneWidget);

    // 2. Tap "Add Signature" button to open popup modal
    await tester.tap(find.byKey(const ValueKey('add_signature_btn')));
    await tester.pumpAndSettle();

    // 3. Verify Popup Dialog is opened
    expect(find.byType(SignatureCaptureDialog), findsOneWidget);
    expect(find.text('Niraj Vekariya • Sign inside frame'), findsOneWidget);
    expect(find.byKey(const ValueKey('dialog_done_signature_btn')), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // 4. Draw signature strokes inside popup dialog
    final canvasFinder = find.byKey(const ValueKey('dialog_drawing_canvas'));
    expect(canvasFinder, findsOneWidget);
    await tester.drag(canvasFinder, const Offset(80, 40));
    await tester.pumpAndSettle();

    // 5. Tap "Done" button to save and close popup
    await tester.tap(find.byKey(const ValueKey('dialog_done_signature_btn')));
    await tester.pumpAndSettle();

    // 6. Verify popup is dismissed
    expect(find.byType(SignatureCaptureDialog), findsNothing);

    // 7. Verify signature is now captured and shown on screen!
    expect(capturedSignature.any((p) => p != null), isTrue);
    expect(find.text('Signed'), findsOneWidget);
    expect(find.text('Signature captured!'), findsOneWidget);
    expect(find.text('Digital Signature'), findsOneWidget);
    expect(find.byKey(const ValueKey('signature_edit_btn')), findsOneWidget);
    expect(find.text('Re-sign'), findsOneWidget);

    // 8. Test Re-sign: tap Re-sign to open dialog again
    await tester.tap(find.byKey(const ValueKey('signature_edit_btn')));
    await tester.pumpAndSettle();
    expect(find.byType(SignatureCaptureDialog), findsOneWidget);

    // Close via Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(SignatureCaptureDialog), findsNothing);

    // 9. Clear signature
    await tester.tap(find.byKey(const ValueKey('signature_clear_btn')));
    await tester.pumpAndSettle();

    // Verify reverted to empty state with Add Signature button
    expect(find.text('Required'), findsOneWidget);
    expect(find.byKey(const ValueKey('add_signature_btn')), findsOneWidget);
  });

  testWidgets('Signature popup supports multi-stroke drawing (first stroke, lift finger, second stroke)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    List<Offset?> capturedSignature = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignaturePadWidget(
            signerName: 'Niraj Vekariya',
            title: 'Main Guest Signature',
            initialPoints: const [],
            onSignatureChanged: (points) {
              capturedSignature = List.from(points);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.byKey(const ValueKey('add_signature_btn')));
    await tester.pumpAndSettle();

    final canvasFinder = find.byKey(const ValueKey('dialog_drawing_canvas'));
    expect(canvasFinder, findsOneWidget);

    // Stroke 1: drag first line
    final gesture1 = await tester.startGesture(tester.getCenter(canvasFinder) - const Offset(50, 0));
    await gesture1.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture1.up();
    await tester.pumpAndSettle();

    // Stroke 2: lift finger and drag second line (e.g. crossing a 't' or second letter)
    final gesture2 = await tester.startGesture(tester.getCenter(canvasFinder) + const Offset(10, -20));
    await gesture2.moveBy(const Offset(40, 10));
    await tester.pump();
    await gesture2.up();
    await tester.pumpAndSettle();

    // Verify both strokes are present in canvas points (delimited by null)
    // Save signature
    await tester.tap(find.byKey(const ValueKey('dialog_done_signature_btn')));
    await tester.pumpAndSettle();

    // Verify multi-stroke captured: contains multiple points and at least one null separator
    expect(capturedSignature.isNotEmpty, isTrue);
    final nullCount = capturedSignature.where((p) => p == null).length;
    expect(nullCount, greaterThanOrEqualTo(2), reason: 'Two distinct strokes must be ended with null');
    expect(find.text('Signed'), findsOneWidget);
    expect(find.text('Signature captured!'), findsOneWidget);
  });
}
