import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'package:image_picker/image_picker.dart';

class CurrentWork extends StatefulWidget {
  final Map<String, dynamic> service;
  const CurrentWork({Key? key, required this.service}) : super(key: key);

  @override
  State<CurrentWork> createState() => _CurrentWorkState();
}

class _CurrentWorkState extends State<CurrentWork> {
  String _accessToken = '';
  bool _isWarrenty = false;
  String _refreshToken = '';
  List<dynamic> services = [];
  List<dynamic> serviceEntries = [];
  Map<String, dynamic>? serviceEntry;
  bool isLoading = false;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    services = [widget.service];
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadTokens();
    await _fetchServiceEntries();
    await Future.wait([
    _checkWarrantyStatus(),  // <-- ADD THIS
  ]);
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accessToken = prefs.getString('AT') ?? '';
      _refreshToken = prefs.getString('RT') ?? '';
    });
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken.isEmpty) return;

    final url = '${Data.baseUrl}/log/token/refresh/';
    final requestBody = {'refresh': _refreshToken};

    try {
      final response = await _dio.post(
        url,
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final newAccessToken = response.data['access'];
      if (newAccessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('AT', newAccessToken);

        setState(() {
          _accessToken = newAccessToken;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
  }

  Future<void> _checkWarrantyStatus() async {
  await _refreshAccessToken(); // ensure fresh token

  try {
    final response = await _dio.get(
      '${Data.baseUrl}/services/is-warranty/${widget.service['id']}/',
      options: Options(
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      ),
    );


    setState(() {
      _isWarrenty = response.data['isWarranty'] ?? false;
    });
  } catch (e) {
    debugPrint("Error checking warranty status: $e");
    setState(() {
      _isWarrenty = false;
    });
  }
}


  Future<void> _fetchServiceEntries() async {
    try {
      final response = await _dio.get(
        '${Data.baseUrl}/api/service-entry/by-service/${widget.service['id']}/',
        options: Options(headers: {
          'Authorization': 'Bearer $_accessToken',
        }),
      );

      setState(() {
        serviceEntries = response.data;
      });
    } catch (e) {
      debugPrint("Error fetching service entries: $e");
      
    }
  }

  void _showServiceEntryDetails(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Service Entry Details"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entry.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text("${e.key}: ${e.value ?? 'N/A'}"),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Future<void> _showEditServiceEntryDialog(Map<String, dynamic> entry) async {
    final TextEditingController nextServiceController = TextEditingController(text: entry['next_service'] ?? '');
    final TextEditingController workDetailsController = TextEditingController(text: entry['work_details'] ?? '');
    final TextEditingController partsReplacedController = TextEditingController(text: entry['parts_replaced'] ?? '');
    final TextEditingController icrNumberController = TextEditingController(text: entry['icr_number'] ?? '');
    final TextEditingController amountChargedController = TextEditingController(text: entry['amount_charged']?.toString() ?? '');
    final TextEditingController signatureByController = TextEditingController(text: entry['Signature_By'] ?? '');

    String visitType = entry['visit_type'] ?? 'C';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Edit Service Entry"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nextServiceController,
                      decoration: const InputDecoration(labelText: "Next Service Date", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () {
                            final nextDate = DateTime.now().add(Duration(days: 30));
                            nextServiceController.text = nextDate.toIso8601String().split('T')[0];
                          },
                          child: const Text("1 Month"),
                        ),
                        TextButton(
                          onPressed: () {
                            final nextDate = DateTime.now().add(Duration(days: 90));
                            nextServiceController.text = nextDate.toIso8601String().split('T')[0];
                          },
                          child: const Text("3 Months"),
                        ),
                        TextButton(
                          onPressed: () {
                            final nextDate = DateTime.now().add(Duration(days: 180));
                            nextServiceController.text = nextDate.toIso8601String().split('T')[0];
                          },
                          child: const Text("6 Months"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: visitType,
                      items: ['I', 'C', 'MS', 'CS', 'CC']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => visitType = val!,
                      decoration: const InputDecoration(labelText: "Visit Type", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: workDetailsController,
                      decoration: const InputDecoration(labelText: "Work Details", border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: partsReplacedController,
                      decoration: const InputDecoration(labelText: "Parts Replaced", border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: icrNumberController,
                      decoration: const InputDecoration(labelText: "ICR Number", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountChargedController,
                      decoration: const InputDecoration(labelText: "Amount Charged", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: signatureByController,
                      decoration: const InputDecoration(labelText: "Signature By", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editServiceEntry(entry['id'], {
                    'next_service': nextServiceController.text,
                    'visit_type': visitType,
                    'work_details': workDetailsController.text,
                    'parts_replaced': partsReplacedController.text,
                    'icr_number': icrNumberController.text,
                    'amount_charged': amountChargedController.text,
                    'signature_by': signatureByController.text,
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3763AE), foregroundColor: Colors.white),
                child: const Text("Update"),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _deleteServiceEntry(int id) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this service entry?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _refreshAccessToken();

    try {
      await _dio.delete(
        '${Data.baseUrl}/api/serviceentry/delete/$id/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleted successfully."), backgroundColor: Color.fromARGB(255, 42, 99, 44)),
      );

      await _fetchServiceEntries(); // Refresh list
    } catch (e) {
      debugPrint("Error deleting service entry: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delete failed."), backgroundColor: Color.fromARGB(255, 151, 40, 32)),
      );
    }
  }


  Future<void> _editServiceEntry(int id, Map<String, dynamic> userInput) async {
    await _refreshAccessToken();

    FormData formData = FormData.fromMap({
      "next_service": userInput['next_service'],
      "visit_type": userInput['visit_type'],
      "work_details": userInput['work_details'],
      "parts_replaced": userInput['parts_replaced'],
      "icr_number": userInput['icr_number'],
      "amount_charged": userInput['amount_charged'],
      "Signature_By": userInput['signature_by'],
    });

    try {
      await _dio.patch(
        '${Data.baseUrl}/api/editserviceentry/$id/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service entry updated successfully"), backgroundColor: Color.fromARGB(255, 42, 97, 44)),
      );

      await _fetchServiceEntries(); // Refresh list
    } catch (e) {
      debugPrint("Error updating service entry: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update entry"), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _createServiceEntry(Map<String, dynamic> service, Map<String, String> userInput) async {
    await _refreshAccessToken();

    FormData formData = FormData.fromMap({
      "service": service['id'],
      "card": service['card'],
      "date": service['available_date'],
      "next_service": userInput['next_service'],
      "visit_type": userInput['visit_type'],
      "nature_of_complaint": service['complaint'],
      "work_details": userInput['work_details'],
      "parts_replaced": userInput['parts_replaced'],
      "icr_number": userInput['icr_number'],
      "amount_charged": userInput['amount_charged'],
      "customer_signature": {"sign": 0},
      "Signature_By": userInput['signature_by'] ?? '',
      "Signature_At": DateTime.now().toIso8601String(),
    });

    if (userInput['image_path'] != null && userInput['image_path']!.isNotEmpty) {
      formData.files.add(MapEntry(
        "Signature_Image",
        await MultipartFile.fromFile(userInput['image_path']!, filename: "signature.jpg"),
      ));
    }

    try {
      await _dio.post(
        '${Data.baseUrl}/api/createserviceentry/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Service entry added successfully!"),
          backgroundColor: Color.fromARGB(255, 51, 119, 54),
        ),
      );

      await _fetchServiceEntries(); // Refresh entries list
    } catch (e) {
      debugPrint("Error creating service entry: $e");
    }
  }

  Future<void> _showServiceEntryDialog(BuildContext context, Map<String, dynamic> service) async {
    final TextEditingController nextServiceController = TextEditingController();
    final TextEditingController workDetailsController = TextEditingController();
    final TextEditingController partsReplacedController = TextEditingController();
    final TextEditingController icrNumberController = TextEditingController();
    final TextEditingController amountChargedController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    final TextEditingController signatureByController = TextEditingController();

    String visitType = 'C';
    XFile? selectedImage;

    if (serviceEntry != null && serviceEntry!['signature_by'] != null) {
      signatureByController.text = serviceEntry!['signature_by'];
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Enter Service Details"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      
                      TextFormField(
                        controller: nextServiceController,
                        decoration: const InputDecoration(
                          labelText: "Next Service Date",
                          hintText: "YYYY-MM-DD",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () {
                              final nextDate = DateTime.now().add(Duration(days: 30));
                              nextServiceController.text = nextDate.toIso8601String().split('T')[0];
                            },
                            child: const Text("1 Month"),
                          ),
                          TextButton(
                            onPressed: () {
                              final nextDate = DateTime.now().add(Duration(days: 90));
                              nextServiceController.text = nextDate.toIso8601String().split('T')[0];
                            },
                            child: const Text("3 Months"),
                          ),
                          TextButton(
                            onPressed: () {
                              final nextDate = DateTime.now().add(Duration(days: 180));
                              nextServiceController.text = nextDate.toIso8601String().split('T')[0];
                            },
                            child: const Text("6 Months"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: visitType,
                        items: ['I', 'C', 'MS', 'CS', 'CC']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => visitType = val!,
                        decoration: const InputDecoration(
                          labelText: "Visit Type",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: workDetailsController,
                        decoration: const InputDecoration(labelText: "Work Details", border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: partsReplacedController,
                        decoration: const InputDecoration(labelText: "Parts Replaced", border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: icrNumberController,
                        decoration: const InputDecoration(labelText: "ICR Number", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountChargedController,
                        decoration: const InputDecoration(labelText: "Amount Charged", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      if (service['OTP_Verification'] == true)
                        TextFormField(
                          controller: otpController,
                          decoration: const InputDecoration(labelText: "Enter OTP", border: OutlineInputBorder()),
                        )
                      else ...[
                        TextFormField(
                          controller: signatureByController,
                          decoration: const InputDecoration(labelText: "Signature By", border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedImage = await picker.pickImage(source: ImageSource.gallery);
                            setState(() {
                              selectedImage = pickedImage;
                            });
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text("Upload Customer Signature"),
                        ),
                        if (selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text("Selected: ${selectedImage!.name}"),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createServiceEntry(service, {
                      'next_service': nextServiceController.text,
                      'visit_type': visitType,
                      'work_details': workDetailsController.text,
                      'parts_replaced': partsReplacedController.text,
                      'icr_number': icrNumberController.text,
                      'amount_charged': amountChargedController.text,
                      'otp': otpController.text,
                      'image_path': selectedImage?.path ?? '',
                      'signature_by': signatureByController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 55, 99, 174),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Submit"),
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
      appBar: AppBar(
        title: const Text("Current Service Details", style: TextStyle(color: Color.fromARGB(255, 55, 99, 174))),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
              ? const Center(
                  child: Text("No Service Available Currently", style: TextStyle(fontSize: 20, color: Colors.grey)),
                )
              : _buildServiceCard(services.last),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      
      child: Card(
        
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color.fromARGB(255, 55, 99, 174), width: 2),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _isWarrenty== true ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isWarrenty== true ? const Color.fromARGB(255, 49, 114, 51) : const Color.fromARGB(255, 165, 34, 25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isWarrenty== true ? Icons.verified : Icons.error_outline,
                              color: _isWarrenty== true ? const Color.fromARGB(255, 52, 121, 54) : const Color.fromARGB(255, 160, 32, 23),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isWarrenty== true
                                    ? "This service is under warranty."
                                    : "This service is not under warranty.",
                                style: TextStyle(
                                  color: _isWarrenty== true ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              Text('Service ID: ${service['id']}', style: const TextStyle(fontSize: 18)),
              Text('Card ID: ${service['card']}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Text('${service['customer_data']['name']},', style: const TextStyle(fontSize: 18)),
              Text('${service['customer_data']['address']},', style: const TextStyle(fontSize: 18)),
              Text('${service['customer_data']['city']}, ${service['customer_data']['district']}.', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text('Phone: ${service['customer_data']['phone']}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Text('Complaint: ${service['complaint']}', style: const TextStyle(fontSize: 18)),
              Text('Description: ${service['description']}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Text('Service Date: ${service['available_date']}',
                  style: const TextStyle(fontSize: 18, color: Color.fromARGB(255, 55, 99, 174))),
              Text('Date Of Booking: ${service['created_at'].toString().split('T')[0]}',
                  style: const TextStyle(fontSize: 18)),
              Text('Verification: ${service['OTP_Verification'] ? "OTP Verification" : "Signature Verification"}',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),

              /// Service Entry Box
              const Text("Previous Service Entries", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  border: Border.all(color: Color(0xFF3763AE), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: serviceEntries.isEmpty
                    ? const Center(child: Text("No entries yet."))
                    : ListView.separated(
                        itemCount: serviceEntries.length,
                        itemBuilder: (context, index) {
                          final entry = serviceEntries[index];
                          return ListTile(
                            title: Text("Entry ID: ${entry['id']}"),
                            subtitle: Text("Date: ${entry['date'] ?? 'N/A'}"),
                            onTap: () => _showServiceEntryDetails(entry),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF3763AE)),
                                  onPressed: () => _showEditServiceEntryDialog(entry),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Color.fromARGB(255, 175, 16, 4)),
                                  onPressed: () => _deleteServiceEntry(entry['id']),
                                ),
                              ],
                            ),

                          );
                        },
                        separatorBuilder: (context, index) => Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: const Divider(height: 1, color: Colors.grey),
                          ),
                        ),
                      ),


              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 55, 99, 174),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    fixedSize: const Size(250, 45),
                  ),
                  onPressed: () {
                    _showServiceEntryDialog(context, service);
                  },
                  child: const Text("Add Service Entries", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
