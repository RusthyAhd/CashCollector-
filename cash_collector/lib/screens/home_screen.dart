import 'package:cash_collector/screens/shoplistscreen.dart';
import 'package:cash_collector/screens/stocklist.dart';
import 'package:cash_collector/screens/termsandconditions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final String googleFormUrl =
      "https://docs.google.com/forms/d/e/1FAIpQLSfZOSjqEHGOQuRZeCr6XF7JWrqLbFronAMdiHJ28d853Nau8g/viewform?usp=header";
  bool isBalanceLoading = true;
  bool isTodayCollectionLoading = true;
  bool isWeekCollectionLoading = true;
  double totalPaidAcrossRoutes = 0;
  bool isUploading = false;
  double totalPaidTodayAmount = 0;
  double totalPaidThisWeekAmount = 0;
  double targetCollectAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTotalPaidAcrossAllRoutes();
    _fetchWeekCollected();
    _fetchTotalPaidToday();
    _fetchTargetCollectAmount();
  }

  Future<void> _launchForm() async {
    final Uri uri = Uri.parse(googleFormUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch the Google Form')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchTargetCollectAmount() async {
    final doc =
        await FirebaseFirestore.instance.collection('admin').doc('stats').get();

    if (doc.exists && doc.data()!.containsKey('targetWeek')) {
      setState(() {
        targetCollectAmount = (doc['targetWeek'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _fetchTotalPaidAcrossAllRoutes() async {
    setState(() => isBalanceLoading = true);
    double totalPaid = 0;

    final routesSnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    for (var routeDoc in routesSnapshot.docs) {
      final shopsSnapshot = await routeDoc.reference.collection('shops').get();

      for (var shopDoc in shopsSnapshot.docs) {
        final shopData = shopDoc.data();
        final shopTotalPaid = (shopData['totalPaid'] ?? 0).toDouble();

        // ✅ Total across all time
        totalPaid += shopTotalPaid;
      }
    }

    // ✅ Save to Firestore
    await FirebaseFirestore.instance.collection('admin').doc('summary').set({
      'latestTotalPaid': totalPaid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ Update local state
    setState(() {
      totalPaidAcrossRoutes = totalPaid;
      isBalanceLoading = false;
    });
  }

  Future<void> _fetchWeekCollected() async {
    setState(() => isWeekCollectionLoading = true);
    final now = DateTime.now();

    // Get Monday and Sunday of the current week
    final int currentWeekday = now.weekday; // Monday = 1, Sunday = 7
    final DateTime mondayThisWeek =
        now.subtract(Duration(days: currentWeekday - 1));
    final DateTime sundayThisWeek = mondayThisWeek.add(const Duration(days: 6));

    final Timestamp startOfWeek = Timestamp.fromDate(DateTime(
      mondayThisWeek.year,
      mondayThisWeek.month,
      mondayThisWeek.day,
      0,
      0,
      0,
    ));

    final Timestamp endOfWeek = Timestamp.fromDate(DateTime(
      sundayThisWeek.year,
      sundayThisWeek.month,
      sundayThisWeek.day,
      23,
      59,
      59,
    ));

    double total = 0;

    // Fetch all deductions in this week range
    final deductionsSnapshot = await FirebaseFirestore.instance
        .collection('deductions')
        .where('sentAt', isGreaterThanOrEqualTo: startOfWeek)
        .where('sentAt', isLessThanOrEqualTo: endOfWeek)
        .get();

    for (var doc in deductionsSnapshot.docs) {
      final data = doc.data();
      final type = data['type'];
      final amount = (data['amount'] ?? 0).toDouble();
// Include if type is not 'Credit'
      if (type == null || type == 'paid' || type != 'Credit') {
        total += amount;
      }
    }

    setState(() {
      totalPaidThisWeekAmount = total;
      isWeekCollectionLoading = false;
    });
    await FirebaseFirestore.instance.collection('admin').doc('summary').set({
      'todayTotalPaid': total,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _fetchTotalPaidToday() async {
    setState(() => isTodayCollectionLoading = true);
    double totalPaidToday = 0;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final routesSnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    for (var routeDoc in routesSnapshot.docs) {
      final shopsSnapshot = await routeDoc.reference.collection('shops').get();

      for (var shopDoc in shopsSnapshot.docs) {
        final transactionsSnapshot = await shopDoc.reference
            .collection('transactions')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .get();

        for (var txnDoc in transactionsSnapshot.docs) {
          final txnData = txnDoc.data();
          final type = txnData['type'];
          final amount = (txnData['amount'] ?? 0).toDouble();
          if (type == null || type == 'paid' || type != 'Credit') {
            totalPaidToday += amount;
          }
        }
      }
    }

    // Optional: Update local state
    setState(() {
      totalPaidTodayAmount = totalPaidToday;
      isTodayCollectionLoading = false;
    });

    // Optional: Save to Firestore summary
    await FirebaseFirestore.instance.collection('admin').doc('summary').set({
      'todayTotalPaid': totalPaidToday,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                setState(() {
                  isUploading = true;
                  isTodayCollectionLoading = true;
                  isWeekCollectionLoading = true;
                });
                await _fetchTotalPaidAcrossAllRoutes();
                setState(() {
                  isUploading = false;
                  isTodayCollectionLoading = false;
                  isWeekCollectionLoading = false;
                });
              },
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.question_mark_outlined),
            tooltip: "Terms & Conditions",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TermsAndConditionsPage()),
              );
            },
          ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    icon: const Icon(Icons.inventory_2_rounded,
                        color: Colors.teal),
                    tooltip: 'View Stock',
                    iconSize: 32,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 227, 245, 236),
                      foregroundColor: const Color.fromARGB(255, 201, 238, 178),
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CollectorStockListPage(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _launchForm,
                    icon: Icon(Icons.upload_file),
                    label: Text("Upload Reciept "),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade100,
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Card(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isBalanceLoading
                          ? const SpinKitThreeBounce(
                              color: Colors.green,
                              size: 24.0,
                            )
                          : Text(
                              "Balance in Hand: Rs.${totalPaidAcrossRoutes.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                    )),
                  ),
                  const SizedBox(height: 8),
                  isTodayCollectionLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.green,
                          size: 20.0,
                        )
                      : Center(
                          child: Text(
                            "Today Collection: Rs.${totalPaidTodayAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: Colors.green[700], fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 4),
                  isWeekCollectionLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.blue,
                          size: 20.0,
                        )
                      : Center(
                          child: Text(
                            "Paid This Week: Rs.${totalPaidThisWeekAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: Colors.blue[700], fontSize: 16),
                          ),
                        ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 32, color: Colors.deepOrangeAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Target of This Week",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rs. ${targetCollectAmount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
