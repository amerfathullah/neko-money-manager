import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _isLoading = false;

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Data
      final ledgers = await ref.read(ledgerProvider.future);
      final categories = await ref.read(categoryProvider.future);
      final transactions = await ref
          .read(transactionRepositoryProvider)
          .getAllTransactions();

      // 2. Prepare JSON-safe Map
      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'ledgers': ledgers
            .map((l) => l.toJson())
            .toList(), // Ledger toJson is simple types
        'categories': categories
            .map((c) => c.toJson())
            .toList(), // Category toJson is simple types
        'transactions': transactions.map((t) {
          final json = t.toJson();
          // Convert Timestamp to ISO String for JSON export
          json['date'] = t.date.toIso8601String();
          return json;
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      if (mounted) {
        _showExportDialog(jsonString);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showExportDialog(String jsonString) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copy this JSON to save your data.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).cardColor,
                height: 200,
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Text(
                    jsonString,
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_download_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Safeguard your data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Export your data to a JSON file for safekeeping.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Data to JSON'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
            // Restore functionality could be added here in future
            const SizedBox(height: 16),
            const Text(
              'Restore functionality coming soon!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
