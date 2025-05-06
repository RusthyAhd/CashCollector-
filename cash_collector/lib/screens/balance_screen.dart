import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BalanceScreen extends StatefulWidget {
  final String shopName;
  final String routeName;
  final String shopId;
  final Function(String shopName, double reducedAmount) onBalanceAdjusted;

  const BalanceScreen({
    super.key,
    required this.shopName,
    required this.routeName,
    required this.shopId,
    required this.onBalanceAdjusted,
  });

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  double? balanceAmount;

  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    final shopRef = FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.routeName)
        .collection('shops')
        .doc(widget.shopId);

    final doc = await shopRef.get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        balanceAmount = (data?['amount'] ?? 0).toDouble();
      });
    }

    // Fetch transactions
    final txSnapshot = await shopRef
        .collection('transactions')
        .orderBy('time', descending: true) // optional ordering
        .get();

    final txList = txSnapshot.docs.map((doc) {
      final tx = doc.data();
      return {
        'store': tx['store'] ?? '',
        'time': tx['time'],
        'amount': tx['amount'],
        'type': tx['type'] ?? 'Cash',
      };
    }).toList();

    setState(() {
      transactions = txList;
    });
  }

  void _showAdjustDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Adjust Balance"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: "Enter amount to reduce",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = controller.text;
                final double? reduction = double.tryParse(input);
                if (reduction != null &&
                    reduction > 0 &&
                    reduction <= (balanceAmount ?? 0)) {
                  final newBalance = (balanceAmount ?? 0) - reduction;

                  // Update Firestore
                  await FirebaseFirestore.instance
                      .collection('routes')
                      .doc(widget.routeName)
                      .collection('shops')
                      .doc(widget.shopId)
                      .update({
                    'amount': newBalance,
                    'status': newBalance == 0 ? 'Unpaid' : 'Paid',
                  });

// ✅ Add transaction to `transactions` subcollection
                  await FirebaseFirestore.instance
                      .collection('routes')
                      .doc(widget.routeName)
                      .collection('shops')
                      .doc(widget.shopId)
                      .collection('transactions')
                      .add({
                    'amount': reduction,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  setState(() {
                    balanceAmount = newBalance;
                  });

                  widget.onBalanceAdjusted(widget.shopName, reduction);
                  Navigator.pop(context); // Close input dialog

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text(
                          "Successfully reduced LKR ${reduction.toStringAsFixed(2)} from balance."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            Navigator.pop(context);
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid amount entered")),
                  );
                }
              },
              child: const Text("Enter"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text(widget.shopName),
              leading: const BackButton(),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'My Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  balanceAmount == null
                      ? const CircularProgressIndicator()
                      : Text(
                          '${balanceAmount!.toStringAsFixed(2)} LKR',
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please click adjust button to reduce collected amount',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _showAdjustDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('ADJUST'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Transaction Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx['store']!,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                              tx['time'] != null
                                  ? (tx['time'] as Timestamp)
                                      .toDate()
                                      .toString()
                                      .substring(0, 16)
                                  : 'Unknown',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          'LKR ${tx['amount'].toString()}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
