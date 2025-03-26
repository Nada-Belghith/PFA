import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quorum_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final QuorumService _quorumService = QuorumService(
    rpcUrl: QuorumService.defaultRpcUrl,
    privateKey: 'YOUR_PRIVATE_KEY_HERE',
  );
  List<CollectionRecord> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final address = 'YOUR_WALLET_ADDRESS';
      final records = await _quorumService.getCollectorTransactions(address);
      setState(() {
        transactions = records;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historique des Transactions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      'Poubelle: ${tx.trashBinId}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${tx.date} à ${tx.time}'),
                        Text('Bouteilles: ${tx.bottleCount}'),
                        Text('Montant: ${tx.amount.toStringAsFixed(3)} DT'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
