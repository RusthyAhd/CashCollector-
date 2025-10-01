// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class CollectorStockListPage extends StatelessWidget {
//   const CollectorStockListPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Stock Items"),
//         backgroundColor: Colors.green.shade700,
//       ),
//       backgroundColor: const Color(0xFFF6F8FA),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('stocks').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("No stocks found"));
//           }

//           final stocks = snapshot.data!.docs;

//           return ListView.builder(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             itemCount: stocks.length,
//             itemBuilder: (context, index) {
//               final data = stocks[index].data() as Map<String, dynamic>;

//               final isAvailable = data['isAvailable'] ?? true;

//               return Container(
//                 margin: const EdgeInsets.only(bottom: 14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.07),
//                       offset: const Offset(0, 4),
//                       blurRadius: 10,
//                     )
//                   ],
//                 ),
//                 child: ListTile(
//                   contentPadding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                   leading: ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
//                         ? Image.network(
//                             data['imageUrl'],
//                             width: 60,
//                             height: 60,
//                             fit: BoxFit.cover,
//                             loadingBuilder: (context, child, loadingProgress) {
//                               if (loadingProgress == null) return child;
//                               return const SizedBox(
//                                 width: 60,
//                                 height: 60,
//                                 child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
//                               );
//                             },
//                             errorBuilder: (_, __, ___) => _placeholderImage(),
//                           )
//                         : _placeholderImage(),
//                   ),
//                   title: Text(
//                     data['name'] ?? 'Unnamed Item',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 17,
//                     ),
//                   ),
//                   subtitle: Padding(
//                     padding: const EdgeInsets.only(top: 6),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _priceRow("Original", data['originalPrice']),
//                         _priceRow("Discounted", data['discountedPrice']),
//                         _priceRow("Last Lowest", data['lastLowerPrice']),
//                       ],
//                     ),
//                   ),
//                   trailing: isAvailable
//                       ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
//                       : Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade600,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: const Text(
//                             "Unavailable",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _priceRow(String label, dynamic price) {
//     return Text(
//       "$label Price: Rs. ${price ?? 'N/A'}",
//       style: const TextStyle(fontSize: 14, color: Colors.black87),
//     );
//   }

//   Widget _placeholderImage() {
//     return Container(
//       width: 60,
//       height: 60,
//       color: Colors.grey.shade300,
//       child: const Icon(Icons.image_not_supported, color: Colors.white70, size: 32),
//     );
//   }
// }
