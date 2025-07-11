import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'data.dart';
import 'index.dart';
import 'login_page.dart';
import '../app_localizations.dart';

class ServiceBook extends StatefulWidget {
  const ServiceBook({super.key});

  @override
  ServiceBookState createState() => ServiceBookState();
}

class ServiceBookState extends State<ServiceBook> {
  String _verificationMethod = 'signature'; // Default verification method
  String _refreshToken = '';
  String _accessToken = '';
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedComplaint;
  TextEditingController otherComplaintController = TextEditingController();
  TextEditingController complaintDetailsController = TextEditingController();
  String? _customerId;
  List<Map<String, dynamic>> cardData = [];
  final Dio _dio = Dio();
  String? selectedCard;

  List<String> complaints = ["General Visit", "Others"];

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadTokens(); 
    await _refreshAccessToken();
    await fetchData();
    await fetchCards(); 
  }

  Future<void> fetchData() async {
    try {
      Response response = await _dio.get('${Data.baseUrl}/media/data.json');
      if (response.statusCode == 200) {
        setState(() {
          complaints = List<String>.from(response.data['complaints'] ?? ["General Visit", "Others"]);
        });
      }
    } catch (e) {
      print('Error fetching complaints: $e');
    }
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshToken = prefs.getString('RT') ?? ''; 
      _accessToken = prefs.getString('AT') ?? ''; 
    });
  }

  Future<void> _loadCustomerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _customerId = prefs.getString('customer_id');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken.isEmpty) {
      debugPrint("No refresh token found! Logging out...");
      await _logout();
      return;
    }

    final url = "${Data.baseUrl}/log/token/refresh/";
    final requestBody = {'refresh': _refreshToken};

    try {
      final response = await _dio.post(
        url,
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data['access'] != null) {
        final newAccessToken = response.data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('AT', newAccessToken);

        setState(() {
          _accessToken = newAccessToken;
        });

        debugPrint("Access token refreshed successfully.");
      } else {
        debugPrint("Refresh token is invalid or expired. Logging out...");
        await _logout();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        debugPrint("Refresh token expired. Logging out...");
        await _logout();
      } else {
        debugPrint('Error refreshing token: $e');
      }
    }
  }

  Future<void> fetchCards() async {
    if (_accessToken.isEmpty) {
      debugPrint("No access token available. Cannot fetch cards.");
      return;
    }

    try {
      final response = await _dio.get(
        '${Data.baseUrl}/api/cards-details/',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        }),
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          cardData = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        debugPrint("Unexpected response format: ${response.data}");
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        debugPrint("Access token expired. Refreshing token...");
        await _refreshAccessToken();
        return fetchCards();
      }
      debugPrint('Error fetching cards: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    DateTime initialDate = isFrom
        ? DateTime.now().add(Duration(days: 0)) // "From date" should be at least 10 days from now
        : fromDate != null ? fromDate!.add(Duration(days: 2)) : DateTime.now();

    DateTime firstDate = DateTime(2000); // Allow dates from year 2000
    DateTime lastDate = isFrom
        ? DateTime.now().add(Duration(days: 30)) // "From date" can be up to 60 days ahead
        : (fromDate != null ? fromDate!.add(Duration(days: 10)) : DateTime.now().add(Duration(days: 10))); // "To" date within 10 days of the "From" date

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isFrom) {
          // Check if the "from date" is at least 10 days from today
          if (pickedDate.isBefore(DateTime.now().add(Duration(days: -1)))) {
            // If "from date" is not at least 10 days from now, show an error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('The "From Date" must be from today.')),
            );
          } else {
            fromDate = pickedDate;
          }
        } else {
          // Ensure the "to date" is after the "from date"
          if (fromDate != null && pickedDate.isBefore(fromDate!)) {
            // If "to date" is before the "from date," show an error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('The "To Date" must be after the "From Date".')),
            );
          } else {
            toDate = pickedDate;
          }
        }
      });
    }
  }




  Future<void> _bookService() async {
    if (fromDate == null || toDate == null || selectedComplaint == null || _customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('service_book_fill_fields'))),
      );
      return;
    }

    String complaintText = selectedComplaint == "Others"
        ? otherComplaintController.text
        : selectedComplaint ?? "";

    String complaintDescription = complaintDetailsController.text;

    // final String checkAvailabilityUrl = "${Data.baseUrl}/utils/checkstaffavailability/";

    Map<String, dynamic> availabilityRequestBody = {
      "from_date": "${fromDate!.year}-${fromDate!.month}-${fromDate!.day}",
      "to_date": "${toDate!.year}-${toDate!.month}-${toDate!.day}"
    };
    // try {
    //   Response availabilityResponse = await _dio.post(
    //     checkAvailabilityUrl,
    //     data: availabilityRequestBody,
    //     options: Options(
    //       headers: {
    //         "Content-Type": "application/json",
    //         'Authorization': 'Bearer $_accessToken',
    //       },
    //     ),
    //   );

    //   if (availabilityResponse.data.containsKey("worker_id")) {
    //     int workerId = availabilityResponse.data["worker_id"];
    //     String avaDate = availabilityResponse.data["available"];
    //     await _confirmBooking(workerId, avaDate, complaintText, complaintDescription);
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text(AppLocalizations.of(context).translate('service_book_no_worker'))),
    //     );
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("Error checking staff availability: $e")),
    //   );
    // }
    _confirmBooking(0, availabilityRequestBody["from_date"], complaintText, complaintDescription);
  }

  Future<void> _confirmBooking(int workerId, String avaDate, String complaintText, String complaintDescription) async {
    final String apiUrl = "${Data.baseUrl}/services/";
    int cardId = int.parse(selectedCard!.split('-')[0]);

    Map<String, dynamic> requestBody = {
      "customer": int.parse(_customerId!),
      "staff": null,
      "staff_name": "Waiting...",
      "available": {
        "from": "${fromDate!.year}/${fromDate!.month}/${fromDate!.day}",
        "to": "${toDate!.year}/${toDate!.month}/${toDate!.day}"
      },
      "available_date": avaDate,
      "description": complaintDescription,
      "complaint": complaintText,
      "status": "BD",
      "card": cardId,
      "OTP_Verification": _verificationMethod == 'otp',
    };

    try {
      Response response = await _dio.post(
        apiUrl,
        data: requestBody,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('service_book_success'))),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => IndexPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('service_book_fail'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('service_book_title'),
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        backgroundColor: const Color.fromARGB(255, 55, 99, 174),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        toolbarHeight: 50.h,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Image.network(
                    "${Data.baseUrl}/media/utils/Service_Book.jpg",
                    height: 200.h,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).translate('service_book_available_period'),
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: fromDate == null
                                  ? AppLocalizations.of(context).translate('service_book_from')
                                  : "${fromDate!.day}/${fromDate!.month}/${fromDate!.year}",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: toDate == null
                                  ? AppLocalizations.of(context).translate('service_book_to')
                                  : "${toDate!.day}/${toDate!.month}/${toDate!.year}",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).translate('service_book_select_card'),
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 10.h),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('service_book_card'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  value: selectedCard,
                  items: cardData.map((card) {
                    String displayText = "${card['id']}-${card['model']}";
                    return DropdownMenuItem<String>(
                      value: displayText,
                      child: Text(displayText),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCard = newValue;
                    });
                  },
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).translate('service_book_details'),
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 10.h),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('service_book_complaint_type'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  value: selectedComplaint,
                  items: complaints.map((String complaint) {
                    return DropdownMenuItem<String>(
                      value: complaint,
                      child: Text(complaint),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedComplaint = newValue;
                    });
                  },
                ),
                if (selectedComplaint == "Others") ...[
                  SizedBox(height: 10.h),
                  TextField(
                    controller: otherComplaintController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).translate('service_book_enter_complaint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
                if (selectedComplaint != null && selectedComplaint != "General Visit") ...[
                  SizedBox(height: 10.h),
                  TextField(
                    controller: complaintDetailsController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).translate('service_book_brief_desc'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 30.h),
                
                SizedBox(height: 20.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).translate('service_book_verification_method'),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context).translate('service_book_verification_otp')),
                      value: 'otp',
                      groupValue: _verificationMethod,
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("OTP Generation was currently unvailable. Please use Signature for verification.")),
                        );
                        setState(() {
                          _verificationMethod = 'signature'; // Switch back to signature
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context).translate('service_book_verification_signature')),
                      value: 'signature',
                      groupValue: _verificationMethod,
                      onChanged: (value) {
                        setState(() {
                          _verificationMethod = value!;
                        });
                      },
                    ),
                  ],
                ),

                SizedBox(height: 30.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _bookService,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      backgroundColor: const Color.fromARGB(255, 55, 99, 174),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('service_book_but'),
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
