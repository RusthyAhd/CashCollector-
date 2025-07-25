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
  bool _isProcessing = false;

  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    print('Shop ID: ${widget.shopId}');
    print('Route: ${widget.routeName}');
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
        .orderBy('timestamp', descending: true)
        .get();

    print('Transaction docs fetched: ${txSnapshot.docs.length}');
    for (var doc in txSnapshot.docs) {
      print('Doc: ${doc.id} => ${doc.data()}');
    }

    final txList = txSnapshot.docs
        .where((doc) => (doc.data()['type'] ?? 'Cash') != 'Credit')
        .map((doc) {
      final tx = doc.data();
      return {
        'time': tx['timestamp'],
        'amount': tx['amount'],
        'type': tx['type'] ?? 'Cash',
        'store': widget.shopName,
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
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Adjust Balance"),
              content: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: "Enter amount to reduce",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          final input = controller.text;
                          final double? reduction = double.tryParse(input);

                          if (reduction != null &&
                              reduction > 0 &&
                              reduction <= (balanceAmount ?? 0)) {
                            setStateDialog(() {
                              _isProcessing = true;
                            });

                            final newBalance = (balanceAmount ?? 0) - reduction;

                            try {
                              final shopDoc = FirebaseFirestore.instance
                                  .collection('routes')
                                  .doc(widget.routeName)
                                  .collection('shops')
                                  .doc(widget.shopId);

                              await shopDoc.update({
                                'amount': newBalance,
                                'status': newBalance == 0 ? 'Unpaid' : 'Paid',
                              });

                              await shopDoc.collection('transactions').add({
                                'amount': reduction,
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              setState(() {
                                balanceAmount = newBalance;
                              });

                              widget.onBalanceAdjusted(
                                  widget.shopName, reduction);

                              Navigator.pop(context); // Close dialog

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  content: Text(
                                      "Successfully reduced LKR ${reduction.toStringAsFixed(2)} from balance."),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "OK",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              setStateDialog(() {
                                _isProcessing = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Error reducing balance: $e")),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Invalid amount entered")),
                            );
                          }
                        },
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Enter",
                          style: TextStyle(color: Colors.black),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
void _showFeedbackDialog() {
  final TextEditingController noteController = TextEditingController();
  String selectedReason = '';

  final List<Map<String, String>> reasons = [
    {'emoji': '🚪', 'label': 'Shop was closed'},
    {'emoji': '👤', 'label': 'Shop owner not available'},
    {'emoji': '📉', 'label': 'No business today'},
    {'emoji': '🙅‍♂️', 'label': 'Owner refused to pay'},
    {'emoji': '📝', 'label': 'Other'},
  ];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFDF8F4),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              "Feedback Area",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              ...reasons.map((reason) {
                final isSelected = selectedReason == reason['label'];
                return ListTile(
                  onTap: () {
                    selectedReason = reason['label']!;
                    (context as Element).markNeedsBuild(); // Rebuild dialog
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor:
                      isSelected ? Colors.orange.shade100 : Colors.grey[200],
                  leading: Text(reason['emoji']!, style: const TextStyle(fontSize: 20)),
                  title: Text(reason['label']!,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                );
              }),
              const SizedBox(height: 16),
              const Text("Optional note"),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Eg: Shop was closed due to festival",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Daily shop visits are required. You're responsible for reporting skipped collections.",
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: const Text("Submit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (selectedReason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a reason.")),
                );
                return;
              }

              final note = noteController.text.trim();

              await FirebaseFirestore.instance
                  .collection('routes')
                  .doc(widget.routeName)
                  .collection('shops')
                  .doc(widget.shopId)
                  .collection('feedbacks')
                  .add({
                'reason': selectedReason,
                'note': note,
                'submittedAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Feedback submitted.")),
              );
            },
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
              title: Text("Balance - ${widget.shopName}"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.feedback_outlined),
                  onPressed: _showFeedbackDialog,
                ),
              ],
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
