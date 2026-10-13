import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_own_pms_system/main.dart';
import 'package:my_own_pms_system/features/auth/data/repositories/auth_repository.dart';
import 'package:my_own_pms_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_own_pms_system/features/auth/presentation/bloc/auth_event.dart';
import 'package:my_own_pms_system/features/auth/presentation/bloc/auth_state.dart';
import 'package:my_own_pms_system/features/auth/presentation/pages/splash_screen.dart';
import 'package:my_own_pms_system/features/auth/presentation/pages/login_screen.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/mobile_main_screen.dart';
import 'package:my_own_pms_system/features/auth/data/repositories/authenticated_http_client.dart';

class _FakeHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) _handler;
  _FakeHttpClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  const sampleSuccessJson = '''
{
    "success": true,
    "message": "Login successful.",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhYWUyYjViOTcyZTE4YmM0OTk0MTg4YiIsInJvbGUiOiJIT1RFTF9BRE1JTiIsInRva2VuVHlwZSI6IkFDQ0VTUyIsImlhdCI6MTc5MDQyNDg4NSwiZXhwIjoxNzkwNDI4NDg1fQ.hysAeJ9MfEi_NjngwZgIRkYi8R2xfjR_KHp0xOTRWlw",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhYWUyYjViOTcyZTE4YmM0OTk0MTg4YiIsInRva2VuVHlwZSI6IlJFRlJFU0giLCJpYXQiOjE3OTA0MjQ4ODUsImV4cCI6MTc5MzAxNjg4NX0.l61-wthrvQHvnG5k241nm0hBVP7hoPqwXRQtb0odju0",
    "data": {
        "_id": "6aae2b5b972e18bc4994188b",
        "name": "jatin kakadiya",
        "email": "jatinkakadiya01@gmail.com",
        "role": "HOTEL_ADMIN",
        "mustChangePassword": false,
        "hotel": {
            "_id": "6aae2b5b972e18bc49941888",
            "name": "hotel merigold",
            "slug": "hotel-merigold-7212",
            "status": "ACTIVE",
            "statusReason": "",
            "subscription": {
                "plan": "TRIAL",
                "status": "TRIAL",
                "trialStartDate": "2026-09-19T06:27:39.349Z",
                "trialEndDate": "2026-10-19T06:27:39.349Z",
                "autoRenew": false,
                "daysLeft": 23,
                "totalDays": 30,
                "elapsedDays": 7,
                "elapsedPercentage": 23,
                "isTrialActive": true,
                "isSubActive": false,
                "isExpired": false
            },
            "settings": {
                "bankDetails": {
                    "bankName": "",
                    "accountNumber": "",
                    "ifscCode": "",
                    "beneficiaryName": ""
                },
                "checkInTime": "14:00",
                "checkOutTime": "12:00",
                "timezone": "Asia/Kolkata",
                "currency": "INR",
                "taxPercentage": 0,
                "upiId": "jatinkakadiya234-1@okicici",
                "amenities": [
                    "Free WiFi",
                    "24/7 Room Service",
                    "Air Conditioning"
                ],
                "policies": [
                    "Valid Government ID required at check-in",
                    "No smoking in standard rooms"
                ]
            },
            "supportContact": {
                "phone": "+91 98765 43210",
                "email": "support@cloudhotelier.com",
                "whatsapp": "+919876543210"
            }
        }
    }
}
''';

  group('Auth Flow & Splash Screen Tests', () {
    test('AuthRepository parses login API response into models correctly', () async {
      final fakeClient = _FakeHttpClient((request) async {
        return http.Response(sampleSuccessJson, 200, headers: {'content-type': 'application/json'});
      });

      final repo = AuthRepository(client: fakeClient);
      final result = await repo.login(
        email: 'jatinkakadiya01@gmail.com',
        password: 'jk@1234',
        rememberStation: false,
      );

      expect(result.success, isTrue);
      expect(result.message, equals('Login successful.'));
      expect(result.data?.email, equals('jatinkakadiya01@gmail.com'));
      expect(result.data?.name, equals('jatin kakadiya'));
      expect(result.data?.role, equals('HOTEL_ADMIN'));
      expect(result.data?.hotel.name, equals('hotel merigold'));
      expect(result.data?.hotel.slug, equals('hotel-merigold-7212'));
    });

    test('AuthRepository throws on invalid credentials response', () async {
      final fakeClient = _FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Invalid email or password.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = AuthRepository(client: fakeClient);
      expect(
        () => repo.login(email: 'wrong@mail.com', password: 'bad', rememberStation: false),
        throwsA(predicate((e) => e.toString().contains('Invalid email or password.'))),
      );
    });

    test('AuthRepository fetchMe parses live /auth/me API response correctly', () async {
      const authMeJson = '''
{
    "success": true,
    "data": {
        "_id": "6abce421513926b760aff5b2",
        "name": "Tushar Paneliya",
        "email": "paneliyatechnology@gmail.com",
        "phone": "8849218118",
        "role": "RECEPTIONIST",
        "hotel": {
            "_id": "6abce211513926b760aff542",
            "name": "Niraj Resort",
            "address": "218, Arth Bussiness Center, Near SP Ring Road",
            "city": "Ahmedabad",
            "state": "Gujarat",
            "country": "India",
            "pincode": "382350",
            "settings": {
                "checkInTime": "14:00",
                "checkOutTime": "12:00"
            }
        },
        "employeeId": "EMP-7779",
        "status": "ACTIVE"
    }
}
''';

      final fakeClient = _FakeHttpClient((request) async {
        if (request.url.toString().contains('/auth/me')) {
          return http.Response(authMeJson, 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"success": false}', 404);
      });

      final repo = AuthRepository(client: fakeClient);
      final user = await repo.fetchMe();

      expect(user, isNotNull);
      expect(user!.name, 'Tushar Paneliya');
      expect(user.email, 'paneliyatechnology@gmail.com');
      expect(user.phone, '8849218118');
      expect(user.role, 'RECEPTIONIST');
      expect(user.initialLetter, 'T');
      expect(user.isActiveShift, true);
      expect(user.hotel.name, 'Niraj Resort');
      expect(user.hotel.address, '218, Arth Bussiness Center, Near SP Ring Road');
      expect(user.hotel.settings.policyScheduleLabel, 'Check-In: 14:00 | Check-Out: 12:00');
    });

    test('AuthBloc emits loading then authenticated on successful login', () async {
      final fakeClient = _FakeHttpClient((request) async {
        return http.Response(sampleSuccessJson, 200, headers: {'content-type': 'application/json'});
      });

      final repo = AuthRepository(client: fakeClient);
      final bloc = AuthBloc(repository: repo);

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const LoginSubmitted(
        email: 'jatinkakadiya01@gmail.com',
        password: 'jk@1234',
        rememberStation: false,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states.length, equals(2));
      expect(states[0].status, equals(AuthStatus.loading));
      expect(states[1].status, equals(AuthStatus.authenticated));
      expect(states[1].user?.name, equals('jatin kakadiya'));
      expect(states[1].user?.hotel.name, equals('hotel merigold'));

      await subscription.cancel();
      await bloc.close();
    });

    testWidgets('SplashScreen renders luxury branding, logo, and terminal loader', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(autoNavigate: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Check Brand Titles and Elements
      expect(find.text('MyOwnPms'), findsOneWidget);
      expect(find.text('CLOUD HOTEL PMS'), findsOneWidget);
      expect(find.text('Hospitality Property Management System'), findsOneWidget);
      expect(find.text('Starting Front Desk Terminal #01...'), findsOneWidget);
      expect(find.byIcon(Icons.holiday_village_rounded), findsOneWidget);
    });

    testWidgets('LoginScreen renders email, password fields, credentials chips, and logs in', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = _FakeHttpClient((request) async {
        return http.Response(sampleSuccessJson, 200, headers: {'content-type': 'application/json'});
      });
      final repo = AuthRepository(client: fakeClient);

      await tester.pumpWidget(
        MyOwnPMSApp(
          authRepository: repo,
          home: LoginScreen(authRepository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Login Screen UI elements & MYOWNPMS Platform Branding
      expect(find.text('MYOWNPMS'), findsOneWidget);
      expect(find.text('NEXT-GEN HOTEL PMS PLATFORM'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Staff Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember station'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign In to Front Desk'), findsOneWidget);

      // Verify demo elements and Mayal Resort branding are removed
      expect(find.text('Mayal Resort 2'), findsNothing);
      expect(find.text('TERMINAL: DESK-01 • READY TO LOG IN'), findsNothing);
      expect(find.text('QUICK DEMO CREDENTIALS'), findsNothing);

      // 2. Test password visibility toggle
      final obscureFinder = find.byIcon(Icons.visibility_outlined);
      expect(obscureFinder, findsOneWidget);
      await tester.tap(obscureFinder);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // 3. Test Forgot Password bottom sheet
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      expect(find.text('Staff Password Reset'), findsOneWidget);
      expect(find.text('+91 98765 43210 • Ext 101'), findsOneWidget);
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Staff Password Reset'), findsNothing);

      // 4. Enter credentials directly into text fields
      final emailField = find.widgetWithText(TextFormField, 'Enter your staff email');
      final passField = find.widgetWithText(TextFormField, 'Enter your password');
      await tester.enterText(emailField, 'jatinkakadiya01@gmail.com');
      await tester.enterText(passField, 'jk@1234');
      await tester.pumpAndSettle();
      expect(find.text('jatinkakadiya01@gmail.com'), findsOneWidget);

      // 6. Test successful sign in
      final signInButton = find.text('Sign In to Front Desk');
      await tester.tap(signInButton);
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));

      // Check that MobileMainScreen is now displayed
      expect(find.byType(MobileMainScreen), findsOneWidget);
      expect(find.text('Front Desk'), findsWidgets);
    });

    testWidgets('LoginScreen shows validation errors on empty fields', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );
      await tester.pumpAndSettle();

      // Clear email and password
      final emailField = find.widgetWithText(TextFormField, 'Enter your staff email');
      final passField = find.widgetWithText(TextFormField, 'Enter your password');

      await tester.enterText(emailField, '');
      await tester.enterText(passField, '');
      await tester.pumpAndSettle();

      // Tap Sign In
      await tester.tap(find.text('Sign In to Front Desk'));
      await tester.pumpAndSettle();

      // Assert validation messages
      expect(find.text('Staff email cannot be empty'), findsOneWidget);
      expect(find.text('Password cannot be empty'), findsOneWidget);
    });

    testWidgets('Sign Out from More Tab navigates back to LoginScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyOwnPMSApp());
      await tester.pumpAndSettle();

      // Tap More nav item
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Scroll to bottom to find Sign Out
      final signOutFinder = find.text('Sign Out / Logout');
      await tester.scrollUntilVisible(signOutFinder, 300);
      await tester.pumpAndSettle();

      await tester.tap(signOutFinder);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Confirm Sign Out'), findsOneWidget);
      await tester.tap(find.text('Confirm Sign Out'));
      await tester.pumpAndSettle();

      // Assert redirected to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In to Front Desk'), findsOneWidget);
    });

    test('AuthRepository saves full login response in SharedPreferences and clears on logout', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeClient = _FakeHttpClient((request) async {
        return http.Response(sampleSuccessJson, 200, headers: {'content-type': 'application/json'});
      });

      final repo = AuthRepository(client: fakeClient);

      // Initially not logged in
      expect(await repo.isLoggedIn(), isFalse);

      // Perform login
      final result = await repo.login(
        email: 'jatinkakadiya01@gmail.com',
        password: 'jk@1234',
      );
      expect(result.success, isTrue);

      // Now session & response are saved in SharedPreferences
      expect(await repo.isLoggedIn(), isTrue);
      final savedResponse = await repo.getSavedLoginResponse();
      expect(savedResponse, isNotNull);
      expect(savedResponse?.accessToken, isNotEmpty);
      expect(savedResponse?.data?.name, equals('jatin kakadiya'));

      final savedToken = await repo.getSavedToken();
      expect(savedToken, equals(result.accessToken));

      // Perform logout -> clears SharedPreferences
      await repo.logout();
      expect(await repo.isLoggedIn(), isFalse);
      expect(await repo.getSavedLoginResponse(), isNull);
      expect(await repo.getSavedToken(), isNull);
    });

    testWidgets('LoginScreen shows login error in SnackBar on API failure', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = _FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Invalid credentials provided.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = AuthRepository(client: fakeClient);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authRepository: repo),
        ),
      );
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'Enter your staff email');
      final passField = find.widgetWithText(TextFormField, 'Enter your password');

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passField, 'wrongpass');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In to Front Desk'));
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify error is displayed in SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid credentials provided.'), findsOneWidget);
    });

    testWidgets('SplashScreen auto redirects to Dashboard if session in SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'dummy_access_token_123',
        'auth_login_response': sampleSuccessJson,
        'auth_user_data': jsonEncode({
          '_id': '6aae2b5b972e18bc4994188b',
          'name': 'jatin kakadiya',
          'email': 'jatinkakadiya01@gmail.com',
          'role': 'HOTEL_ADMIN',
          'hotel': {'name': 'hotel merigold'},
        }),
      });

      final repo = AuthRepository();
      expect(await repo.isLoggedIn(), isTrue);

      await tester.pumpWidget(
        MyOwnPMSApp(
          authRepository: repo,
          home: SplashScreen(
            duration: const Duration(milliseconds: 100),
            autoNavigate: true,
            authRepository: repo,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Automatically redirected to Dashboard
      expect(find.byType(MobileMainScreen), findsOneWidget);
    });

    testWidgets('SplashScreen auto redirects to LoginScreen if no session in SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final repo = AuthRepository();
      expect(await repo.isLoggedIn(), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(milliseconds: 100),
            autoNavigate: true,
            authRepository: repo,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Redirected to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In to Front Desk'), findsOneWidget);
    });

    test('AuthRepository refreshToken calls API with cookie & body and updates SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'old_access_token',
        'auth_refresh_token': 'old_refresh_token',
      });

      late http.BaseRequest capturedRequest;
      final fakeClient = _FakeHttpClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            "success": true,
            "message": "Access token refreshed successfully.",
            "accessToken": "new_access_token_12345",
            "refreshToken": "new_refresh_token_67890"
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = AuthRepository(client: fakeClient);
      final response = await repo.refreshToken();

      expect(response.success, isTrue);
      expect(response.accessToken, equals('new_access_token_12345'));
      expect(response.refreshToken, equals('new_refresh_token_67890'));

      // Check request details
      expect(capturedRequest.url.toString(), equals('https://hotelmanagementbackend-dev.up.railway.app/api/v1/auth/refresh-token'));
      expect(capturedRequest.headers['Cookie'], contains('refreshToken=old_refresh_token'));
      expect(capturedRequest.headers['Cookie'], contains('token=old_access_token'));

      // Check updated SharedPreferences
      expect(await repo.getSavedToken(), equals('new_access_token_12345'));
      expect(await repo.getSavedRefreshToken(), equals('new_refresh_token_67890'));
    });

    test('AuthRepository getValidAccessToken automatically refreshes expired token', () async {
      // Create an expired JWT token (exp in 2020)
      final expiredPayload = base64Url.encode(utf8.encode(jsonEncode({'exp': 1577836800}))).replaceAll('=', '');
      final expiredJwt = 'eyJhbGciOiJIUzI1NiJ9.$expiredPayload.signature';

      SharedPreferences.setMockInitialValues({
        'auth_access_token': expiredJwt,
        'auth_refresh_token': 'valid_refresh_token',
      });

      final fakeClient = _FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({
            "success": true,
            "message": "Access token refreshed successfully.",
            "accessToken": "fresh_access_token",
            "refreshToken": "fresh_refresh_token"
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = AuthRepository(client: fakeClient);
      expect(AuthRepository.isTokenExpired(expiredJwt), isTrue);

      final validToken = await repo.getValidAccessToken();
      expect(validToken, equals('fresh_access_token'));
      expect(await repo.getSavedToken(), equals('fresh_access_token'));
    });

    test('AuthenticatedHttpClient refreshes token and retries on 401 response', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'initial_token',
        'auth_refresh_token': 'refresh_token',
      });

      int apiCallCount = 0;
      final fakeClient = _FakeHttpClient((request) async {
        if (request.url.path.contains('refresh-token')) {
          return http.Response(
            jsonEncode({
              "success": true,
              "message": "Access token refreshed successfully.",
              "accessToken": "retried_token_999",
              "refreshToken": "retried_refresh_999"
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        apiCallCount++;
        if (apiCallCount == 1) {
          // First attempt returns 401
          return http.Response('{"error": "Unauthorized"}', 401);
        }
        // Second attempt with new token returns 200
        return http.Response('{"data": "success"}', 200);
      });

      final repo = AuthRepository(client: fakeClient);
      final client = AuthenticatedHttpClient(authRepository: repo, innerClient: fakeClient);

      final response = await client.get(Uri.parse('https://example.com/api/test'));
      expect(response.statusCode, equals(200));
      expect(apiCallCount, equals(2));
      expect(await repo.getSavedToken(), equals('retried_token_999'));
    });

    test('AuthBloc updates token on TokenRefreshRequested', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'prev_token',
        'auth_refresh_token': 'valid_refresh',
      });

      final fakeClient = _FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({
            "success": true,
            "message": "Access token refreshed successfully.",
            "accessToken": "bloc_new_token",
            "refreshToken": "bloc_new_refresh"
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = AuthRepository(client: fakeClient);
      final bloc = AuthBloc(repository: repo);

      bloc.add(const TokenRefreshRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.status, equals(AuthStatus.authenticated));
      expect(bloc.state.token, equals('bloc_new_token'));

      await bloc.close();
    });
  });
}
