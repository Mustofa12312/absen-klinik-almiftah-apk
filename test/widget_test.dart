import 'package:flutter_test/flutter_test.dart';
import 'package:employee_app/main.dart';

void main() {
  testWidgets('KlinikAlmiftahApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KlinikAlmiftahApp());

    // Verify that the title text is present on SplashScreen.
    expect(find.text('Klinik Al-Miftah'), findsOneWidget);
    expect(find.text('Sistem Absensi Pegawai'), findsOneWidget);

    // Drain the splash screen 2-second timer to avoid pending timer error
    await tester.pump(const Duration(seconds: 3));
  });
}
