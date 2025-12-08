import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neko_money_manager/features/home/presentation/pages/main_scaffold.dart';
import 'package:neko_money_manager/main.dart';
import 'package:neko_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:neko_money_manager/features/categories/data/models/category.dart';
import 'package:neko_money_manager/features/home/presentation/providers/ledger_provider.dart';
import 'package:neko_money_manager/features/home/data/models/ledger.dart';
import 'package:neko_money_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:neko_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:neko_money_manager/features/transactions/data/models/transaction_model.dart';
import 'package:neko_money_manager/features/settings/presentation/providers/pro_provider.dart';

// Mocks
class MockCategoryNotifier extends CategoryNotifier {
  @override
  Stream<List<Category>> build() {
    return Stream.value([
      const Category(
        id: '1',
        name: 'Food',
        iconCodePoint: 0xe532, // Icons.fastfood
        iconFontFamily: 'MaterialIcons',
        colorValue: 0xFFFF0000,
        type: CategoryType.expense,
      ),
      const Category(
        id: '2',
        name: 'Salary',
        iconCodePoint: 0xe232, // Icons.attach_money
        iconFontFamily: 'MaterialIcons',
        colorValue: 0xFF00FF00,
        type: CategoryType.income,
      ),
    ]);
  }
}

class MockLedgerNotifier extends LedgerNotifier {
  @override
  Stream<List<Ledger>> build() {
    return Stream.value([
      const Ledger(
        id: '1',
        name: 'Main Wallet',
        balance: 1000.0,
        colorValue: 0xFF42A5F5,
      ),
    ]);
  }
}

class MockTransactionNotifier extends TransactionNotifier {
  @override
  Stream<List<TransactionModel>> build() {
    return Stream.value([]);
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {}
}

class MockProNotifier extends ProNotifier {
  @override
  Stream<bool> build() {
    return Stream.value(true);
  }
}

void main() {
  testWidgets('NekoApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(null),
          ), // Mock logged out
        ],
        child: const NekoApp(),
      ),
    );

    // Verify that our app starts and demonstrates the home page.
    // Note: This matches the AppBar title in SplashScreen or LoginPage
    expect(find.text('Neko Money Manager'), findsOneWidget);

    // Wait for Splash Screen delay (2 seconds) and navigation
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // After splash, it goes to Login Page
    expect(find.text('Login'), findsWidgets);
  });

  /*
  testWidgets('TransactionPage UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryProvider.overrideWith(MockCategoryNotifier.new),
          ledgerProvider.overrideWith(MockLedgerNotifier.new),
          userIdProvider.overrideWithValue('test_user_id'),
          transactionProvider.overrideWith(MockTransactionNotifier.new),
          proProvider.overrideWith(MockProNotifier.new),
        ],
        child: const MaterialApp(home: TransactionPage()),
      ),
    );

    // Initial load for streams
    await tester.pumpAndSettle();

    expect(find.text('New Transaction'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
  });
  */

  testWidgets('MainScaffold navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryProvider.overrideWith(MockCategoryNotifier.new),
          ledgerProvider.overrideWith(MockLedgerNotifier.new),
          userIdProvider.overrideWithValue('test_user_id'),
          proProvider.overrideWith(MockProNotifier.new),
          ledgerTransactionsProvider.overrideWith(
            (ref, id) => Stream.value([]),
          ),
        ],
        child: const MaterialApp(home: MainScaffold()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('My Wallets'), findsOneWidget);
    expect(find.text('Expense Breakdown'), findsOneWidget);

    // Tap Transactions Tab
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    // Transactions State
    expect(
      find.text('Transactions'),
      findsWidgets,
    ); // AppBar title and Tab label
    expect(find.text('My Wallets'), findsNothing);

    // Tap Settings Tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Settings State
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Expense Breakdown'), findsNothing);

    // Navigate back to Home
    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(seconds: 1)); // Wait for animation

    // Verify Home Page again
    expect(find.text('My Wallets'), findsOneWidget);

    // Navigate to Ledger Details
    // Tap the first ledger card (assuming "Main Wallet" is present from mock)
    await tester.tap(find.text('Main Wallet'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify Ledger Details Page
    // If loading, we'll see CircularProgressIndicator
    if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      debugPrint('Still loading transactions...');
    }

    expect(find.text('Current Balance'), findsOneWidget);
    expect(find.text('Main Wallet'), findsWidgets); // Title and AppBar
  });
}
