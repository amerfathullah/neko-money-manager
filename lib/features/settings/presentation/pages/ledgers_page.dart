import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../../home/presentation/pages/ledger_details_page.dart';
import '../../../../core/theme/app_theme_colors.dart';
import 'add_edit_ledger_page.dart';

class LedgersPage extends ConsumerWidget {
  const LedgersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgersAsync = ref.watch(ledgerProvider);
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledgers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditLedgerPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ledgersAsync.when(
        data: (ledgers) {
          if (ledgers.isEmpty) {
            return Center(
              child: Text(
                'No ledgers found.\nAdd one to get started!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: ledgers.length,
            itemBuilder: (context, index) {
              final ledger = ledgers[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LedgerDetailsPage(ledger: ledger),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      // Top colored section
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: ledger.color, // Vibrant top
                          child: Stack(
                            children: [
                              // Bookmark
                              Positioned(
                                top: -4,
                                left: 8,
                                child: Icon(
                                  Icons.bookmark,
                                  color: Colors.black.withValues(alpha: 0.2),
                                  size: 32,
                                ),
                              ),
                              // Main Icon
                              Center(
                                child: Icon(
                                  ledger.icon ?? Icons.account_balance_wallet,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  // Adding a subtle shadow to icon to make it pop like a sticker
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom pastel section
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: ledger.color.withValues(
                            alpha: 0.2,
                          ), // Pastel bottom
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ledger.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: themeColors.text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
