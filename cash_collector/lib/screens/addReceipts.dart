import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddReceipts extends StatefulWidget {
  final String? stockId;

  const AddReceipts({Key? key, this.stockId}) : super(key: key);

  @override
  State<AddReceipts> createState() => _AddReceiptsState();
}

class _AddReceiptsState extends State<AddReceipts> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;

  Future<String?> uploadToImgur(File imageFile) async {
    const clientId = 'e985f439dbcdd42'; // Replace this with your Imgur Client ID
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://api.imgur.com/3/image'),
      headers: {
        'Authorization': 'Client-ID $clientId',
      },
      body: {
        'image': base64Image,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['link'];
    } else {
      debugPrint('Imgur upload failed: ${response.body}');
      return null;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text("Take a Photo"),
                onTap: () async {
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _imageFile = File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _imageFile = File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;
    return await uploadToImgur(_imageFile!);
  }

  Future<void> _saveReceipts() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    final imageUrl = await _uploadImage();

    final receiptData = {
      'amount': _amountController.text.trim(),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = FirebaseFirestore.instance.collection('receipts');
    if (widget.stockId != null) {
      await docRef.doc(widget.stockId).update(receiptData);
    } else {
      await docRef.add(receiptData);
    }

    setState(() => _isUploading = false);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: Text(widget.stockId != null ? "Edit Receipt" : "Add New Receipt"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text("Uploading... Please wait"),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Text(
                          "Receipt Details",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Amount field
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Amount",
                            prefixIcon: const Icon(Icons.attach_money),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Pick image button
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text("Add Receipt Image"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        // Image preview
                        if (_imageFile != null || _imageUrl != null) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              // fullscreen view
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: InteractiveViewer(
                                    child: _imageFile != null
                                        ? Image.file(_imageFile!)
                                        : Image.network(_imageUrl!),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageFile != null
                                  ? Image.file(_imageFile!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover)
                                  : Image.network(_imageUrl!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover),
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _saveReceipts,
                            child: Text(widget.stockId != null
                                ? 'Update Receipt'
                                : 'Submit Receipt'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
