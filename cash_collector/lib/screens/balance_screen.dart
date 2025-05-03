import 'package:flutter/material.dart';

class BalanceScreen extends StatefulWidget {
  final String shopName;
  final Function(String shopName, double newBalance)
      onBalanceAdjusted; // Add callback

  const BalanceScreen({
    super.key,
    required this.shopName,
    required this.onBalanceAdjusted, // Add callback
  });

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  double balanceAmount = 4933.24;

  final List<Map<String, String>> transactions = [
    {
      'store': 'ABC Store',
      'time': '10:15AM',
      'amount': '\$300',
      'type': 'Cash'
    },
    {
      'store': 'XYZ Mart',
      'time': '9:30AM',
      'amount': '\$150',
      'type': 'Online'
    },
    {
      'store': 'Doe Supplies',
      'time': 'Yesterday',
      'amount': '\$130',
      'type': 'Cash'
    },
  ];

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
              onPressed: () {
                final input = controller.text;
                final double? reduction = double.tryParse(input);
                if (reduction != null && reduction > 0 && reduction <= balanceAmount) {
                  setState(() {
                    balanceAmount -= reduction; // Update the remaining balance locally
                  });

                  // Pass the reduced amount to the callback
                  widget.onBalanceAdjusted(widget.shopName, reduction);

                  Navigator.pop(context); // Close input dialog

                  // Show success dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text(
                          "Successfully reduced LKR ${reduction.toStringAsFixed(2)} from balance."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus(); // Hide keyboard if open
                            Navigator.pop(context); // Close success dialog
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
                  Text(
                    '${balanceAmount.toStringAsFixed(2)} LKR',
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
                            Text(tx['time']!,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Row(
                          children: [
                            Text(tx['amount']!,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: tx['type'] == 'Cash'
                                    ? Colors.grey.shade300
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(tx['type']!,
                                  style: const TextStyle(fontSize: 12)),
                            )
                          ],
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
