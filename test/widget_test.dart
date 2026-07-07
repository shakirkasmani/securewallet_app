import 'package:flutter_test/flutter_test.dart';
import 'package:securewallet_app/main.dart';
import 'package:securewallet_app/screens/wallet_screen.dart';

void main() {
  testWidgets('Wallet screen renders title and cards smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CreditCardVaultApp());

    // Verify that our wallet screen renders with the title 'My Wallet'.
    expect(find.text('My Wallet'), findsOneWidget);

    // Verify that we can find the WalletScreen.
    expect(find.byType(WalletScreen), findsOneWidget);
  });
}
