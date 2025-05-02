import 'package:flutter/material.dart';

class BalanceScreen extends StatelessWidget {
  final String shopName;
  const BalanceScreen({super.key, required this.shopName});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text(shopName),
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
                  const Text(
                    '4933.24 LKR',
                    style: TextStyle(
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adjust button clicked')),
                      );
                    },
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
