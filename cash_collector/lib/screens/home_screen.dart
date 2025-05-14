import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shoplistscreen.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  double totalPaidAcrossRoutes = 0;
  TextEditingController amountSentController = TextEditingController();
  bool isUploading = false;
  String? uploadedFileUrl;

  @override
  void initState() {
    super.initState();
    _fetchTotalPaidAcrossAllRoutes();
  }

  void openGoogleForm() async {
    final amountText = amountSentController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the amount sent")),
      );
      return;
    }

    final double? amountSent = double.tryParse(amountText);
    if (amountSent == null || amountSent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    // ✅ Save the deduction entry for history
    await FirebaseFirestore.instance.collection('deductions').add({
      'amount': amountSent,
      'sentAt': FieldValue.serverTimestamp(),
    });

    // ✅ Save summary
    await FirebaseFirestore.instance.collection('admin').doc('summary').set({
      'lastSentAmount': amountSent,
      'sentAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ Reset all shops with status == 'Paid'
    final routesSnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    for (var routeDoc in routesSnapshot.docs) {
      final shopsSnapshot = await routeDoc.reference.collection('shops').get();

      for (var shopDoc in shopsSnapshot.docs) {
        final shopData = shopDoc.data();
        if (shopData['status'] == 'Paid') {
          await shopDoc.reference.update({
            'status': 'Unpaid',
            'totalPaid': 0,
          });
        }
      }
    }

    // ✅ Reset total paid locally
    setState(() {
      totalPaidAcrossRoutes = 0;
    });

    // 🌐 Open Google Form with amount prefilled
    final formUrl = Uri.encodeFull(
      'https://docs.google.com/forms/d/e/1FAIpQLScQIdIMPBP7sUj7crDtZimYXWNWy-Wiq4oXACgbKxoxqPvHRQ/viewform?usp=pp_url&entry.139912917=$amountSent',
    );

    if (!await launchUrl(Uri.parse(formUrl),
        mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Form")),
      );
    }
  }

  Future<void> _fetchTotalPaidAcrossAllRoutes() async {
    double totalPaid = 0;

    final routesSnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    for (var routeDoc in routesSnapshot.docs) {
      final shopsSnapshot = await routeDoc.reference.collection('shops').get();

      for (var shopDoc in shopsSnapshot.docs) {
        final shopData = shopDoc.data();
        final status = shopData['status'];
        final shopTotalPaid = shopData['totalPaid'];

        if (status == 'Paid' && shopTotalPaid != null) {
          totalPaid += (shopTotalPaid as num).toDouble();
        }
      }
    }

    // ✅ Save totalPaid before deduction to Firestore
    await FirebaseFirestore.instance.collection('admin').doc('summary').set({
      'totalPaidBeforeDeductions': totalPaid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      totalPaidAcrossRoutes = totalPaid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF1),
      appBar: AppBar(
        title: const Text("Choose Area"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                isUploading = true;
              });
              await _fetchTotalPaidAcrossAllRoutes();
              setState(() {
                isUploading = false;
              });
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTotalPaidAcrossAllRoutes,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('routes').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No routes found"));
                  }

                  final routes = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    itemCount: routes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = routes[index];
                      final routeName = doc.id;
                      final emoji = "🛣️";

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 3,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ShopListScreen(routeName: routeName),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                            child: Row(
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    routeName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
             Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Total Paid: Rs.${totalPaidAcrossRoutes.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (uploadedFileUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("Receipt Uploaded ✅",
                          style: const TextStyle(color: Colors.green)),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountSentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount Sent to Owner",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final amountText = amountSentController.text.trim();

                      if (amountText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter an amount.")),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountText);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter a valid amount.")),
                        );
                        return;
                      }

                      // Launch Google Form with prefilled amount
                      final formUrl = Uri.encodeFull(
                        'https://docs.google.com/forms/d/e/1FAIpQLScQIdIMPBP7sUj7crDtZimYXWNWy-Wiq4oXACgbKxoxqPvHRQ/viewform?usp=pp_url&entry.139912917=$amount',
                      );
                      await launchUrl(Uri.parse(formUrl));

                      // Save deduction record
                      await FirebaseFirestore.instance
                          .collection('deductions')
                          .add({
                        'amount': amount,
                        'sentAt': FieldValue.serverTimestamp(),
                      });

                      // Save admin summary
                      await FirebaseFirestore.instance
                          .collection('admin')
                          .doc('summary')
                          .set({
                        'lastSentAmount': amount,
                        'sentAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                      // Step 1: Gather all paid shops
                      final routesSnapshot = await FirebaseFirestore.instance
                          .collection('routes')
                          .get();

                      double remainingToDeduct = amount;

                      for (var routeDoc in routesSnapshot.docs) {
                        final shopsSnapshot =
                            await routeDoc.reference.collection('shops').get();

                        for (var shopDoc in shopsSnapshot.docs) {
                          final shopData = shopDoc.data();

                          if (shopData['status'] == 'Paid') {
                            double shopPaid =
                                (shopData['totalPaid'] ?? 0).toDouble();

                            if (shopPaid == 0 || remainingToDeduct <= 0)
                              continue;

                            double deduction = 0;
                            if (remainingToDeduct >= shopPaid) {
                              // Deduct full shop amount
                              deduction = shopPaid;
                              remainingToDeduct -= shopPaid;

                              // Archive full payment
                              await shopDoc.reference
                                  .collection('transactions')
                                  .add({
                                'type': 'paid',
                                'amount': shopPaid,
                                'resetAt': FieldValue.serverTimestamp(),
                              });

                              // Reset this shop
                              await shopDoc.reference.update({
                                'status': 'Unpaid',
                                'totalPaid': 0,
                              });
                            } else {
                              // Deduct partial amount from this shop
                              deduction = remainingToDeduct;
                              remainingToDeduct = 0;

                              await shopDoc.reference
                                  .collection('transactions')
                                  .add({
                                'type': 'partialPaid',
                                'amount': deduction,
                                'resetAt': FieldValue.serverTimestamp(),
                              });

                              // Update remaining amount in shop
                              await shopDoc.reference.update({
                                'totalPaid': shopPaid - deduction,
                              });

                              // Stop once deduction is complete
                              break;
                            }
                          }
                        }

                        if (remainingToDeduct <= 0) break;
                      }

                      await _fetchTotalPaidAcrossAllRoutes();
                      amountSentController.clear();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Amount submitted and deducted successfully."),
                        ),
                      );
                    },
                    child: Center(child: const Text("Submit Receipt & Amount", style: TextStyle(color: Colors.black),)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 113, 182, 116),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
        ),
        
      ),
    );
  }
}
