import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
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
  ReceiptController? _receiptController;

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
                              reduction > 300 &&
                              reduction <= (balanceAmount ?? 0)) {
                            setStateDialog(() {
                              _isProcessing = true;
                            });

                            final oldBalance = balanceAmount ?? 0;
                            final newBalance = oldBalance - reduction;

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

                              Navigator.pop(context); // Close input dialog

                              // Show receipt dialog
                              _showReceiptDialog(
                                shopName: widget.shopName,
                                oldBalance: oldBalance,
                                reducedAmount: reduction,
                                newBalance: newBalance,
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
                                  content: Text("Invalid amount entered\nAmount must be at least 300")),
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
/// Receipt dialog
void _showReceiptDialog({
  required String shopName,
  required double oldBalance,
  required double reducedAmount,
  required double newBalance,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Pegas Flex\nKinniya 02\n0755354023"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Shop: $shopName", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text("Old Balance: LKR ${oldBalance.toStringAsFixed(2)}"),
            const SizedBox(height: 12),
            Text("Deducted: LKR ${reducedAmount.toStringAsFixed(2)}"),
            const SizedBox(height: 12),
            Text("New Balance: LKR ${newBalance.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 18),
            label: const Text("Print"),
            onPressed: () async {
              // 1️⃣ Select printer device
              final device = await FlutterBluetoothPrinter.selectDevice(context);
              if (device == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No printer selected")),
                );
                return;
              }

              // 2️⃣ Show preview dialog with Exit + Print
              await showDialog(
                context: context,
                barrierDismissible: false, // prevent closing by tapping outside
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Receipt Preview"),
                    content: Receipt(
                      builder: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Pegas Flex\nKinniya 02\n0755354023"),
                          const Divider(),
                          Text("Shop: $shopName"),
                          const SizedBox(height: 10),
                          Text("Old Balance: LKR ${oldBalance.toStringAsFixed(2)}"),
                          const SizedBox(height: 8),
                          Text("Deducted: LKR ${reducedAmount.toStringAsFixed(2)}"),
                          const SizedBox(height: 8),
                          Text("New Balance: LKR ${newBalance.toStringAsFixed(2)}"),
                        ],
                      ),
                      onInitialized: (controller) {
                        _receiptController = controller;
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Exit preview without printing
                        },
                        child: const Text("Exit", style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_receiptController != null) {
                            await _receiptController!.print(address: device.address);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Receipt sent to printer")),
                            );
                          }
                          Navigator.of(context).pop(); // Close preview
                        },
                        child: const Text("Ok", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  );
                },
              );

              Navigator.pop(context); // Close the first dialog
            },
          ),
        ],
      );
    },
  );
}

  void _showFeedbackDialog() {
    String? selectedReason;
    String note = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFFFDF8F4),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Feedback Area",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedReason,
                    items: [
                      'Shop Closed 🏪',
                      'Owner Not Available 🙅‍♂️',
                      'No business today 📉',
                      'Owner refused to pay 💰',
                      'Other ✏️'
                    ]
                        .map((reason) => DropdownMenuItem(
                              value: reason,
                              child: Text(reason),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => note = value,
                  ),
                  Row(
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
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () async {
                    if (selectedReason == null || selectedReason!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a reason'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('feedbacks')
                        .add({
                      'routeName':
                          widget.routeName, // Ensure you pass this to page
                      'shopName':
                          widget.shopName, // Ensure you pass this to page
                      'shopId': widget.shopId,
                      'reason': selectedReason,
                      'note': note,
                      'submittedAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback submitted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            );
          },
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
