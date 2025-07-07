import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'index.dart';
import 'login_page.dart';
import '../app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CardDetailsPage extends StatefulWidget {
  final Map<String, dynamic> cardData;

  const CardDetailsPage({super.key, required this.cardData});

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  String _refreshToken = '';
  String _accessToken = '';
  List<dynamic> products = [];
  bool isLoading = true;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadTokens(); 
    await _refreshAccessToken();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshToken = prefs.getString('RT') ?? ''; 
      _accessToken = prefs.getString('AT') ?? ''; 
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
      _logout();
      return;
    }

    final url = '${Data.baseUrl}/log/token/refresh/';
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
        debugPrint("Unexpected response: ${response.data}");
        _logout();
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          debugPrint("Refresh token expired! Logging out...");
          _logout();
        } else {
          debugPrint("Error refreshing token: ${e.response?.data}");
        }
      } else {
        debugPrint("Error refreshing token: $e");
      }
    }
  }

  void _showSignConfirmationDialog(BuildContext parentContext, BuildContext dialogContext, int serviceId) {
  double rating = 1.0;
  TextEditingController feedbackController = TextEditingController();

  showDialog(
    context: dialogContext,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context).translate('card_confrim_sign')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context).translate('card_confrim_sign_text')),
                  SizedBox(height: 16.h),
                  Text(AppLocalizations.of(context).translate('card_rating')),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                        ),
                        color: Colors.amber,
                        onPressed: () {
                          setDialogState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: feedbackController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).translate('card_feedback'),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context).translate('card_cancel')),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red, // Text color for cancel button
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // close dialog
                  _signService(serviceId, rating, feedbackController.text, parentContext); // use parentContext
                },
                child: Text(AppLocalizations.of(context).translate('card_confirm')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 55, 99, 174), // Button color
                  foregroundColor: Colors.white, // Text color for confirm button
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r), // Rounded corners
                  ),
              ),
              )
            ],
          );
        },
      );
    },
  );
}


  void _signService(int serviceId, double rating, String feedback, BuildContext context) async {
    print(feedback);
    print(rating);
    final url = '${Data.baseUrl}/api/signbycustomer/$serviceId/';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };
    final data = {
      "customer_signature": {"sign": 1},
      "feedback": feedback,
      "rating": rating.toInt(),
    };

    try {
      final response = await _dio.patch(url, data: data, options: Options(headers: headers));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('card_sign_success'))),
        );
        await Future.delayed(Duration(milliseconds: 500)); // wait to let snackbar show
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => IndexPage()),
          (Route<dynamic> route) => false,
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => IndexPage()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('card_sign_fail'))),
        );
      }
    } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      // Access token expired — try refreshing
      await _refreshAccessToken();
      _signService(serviceId, rating, feedback, context); // Retry after refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    }
  }catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _buildServiceInfoRow(BuildContext context, String labelKey, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context).translate(labelKey)} ',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('card_title')),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 55, 99, 174),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Details Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(
                    color: Color.fromARGB(255, 55, 99, 174),
                    width: 1.5.w,
                  ),
                ),
                color: Color.fromARGB(255, 255, 255, 255),
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16.0.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context).translate('card_model')} ${widget.cardData['model']}',
                        style: TextStyle(fontSize: 14.sp, color: Color.fromARGB(255, 55, 99, 174), fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.h),
                      Text('${AppLocalizations.of(context).translate('card_customer_id')}${widget.cardData['customer_code']}'),
                      SizedBox(height: 8.h),
                      Text('${AppLocalizations.of(context).translate('card_date_of_installation')} ${widget.cardData['date_of_installation']}'),
                      SizedBox(height: 8.h),
                      Text('${AppLocalizations.of(context).translate('card_customer_name')} ${widget.cardData['customer_name']}'),
                      SizedBox(height: 8.h),
                      Text('${AppLocalizations.of(context).translate('card_customer_region')} ${widget.cardData['region']}'),
                      SizedBox(height: 16.h),
                      Text(
                        '${AppLocalizations.of(context).translate('card_warrenty_period')} ${widget.cardData['warranty_start_date']} - ${widget.cardData['warranty_end_date']}',
                        style: TextStyle(
                            color: Color.fromARGB(255, 55, 99, 174),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Services List
              if (widget.cardData['service_entries'] != null && widget.cardData['service_entries'] is List)
                for (var service in widget.cardData['service_entries'].reversed)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0.h),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 55, 99, 174),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 30.0.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {

                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: SingleChildScrollView(
                                child: Container(
                                  width: 400.w,
                                  padding: EdgeInsets.all(20.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Row(
                                        children: [
                                          Icon(Icons.build_circle_outlined, color: Theme.of(context).primaryColor),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Text(
                                              '${AppLocalizations.of(context).translate('card_service_no')} ${service['id']}',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      Divider(),

                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: (service['customer_signature'] != null && service['customer_signature']['sign'] != 0) ? Colors.green[50] : Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: (service['customer_signature'] != null && service['customer_signature']['sign'] != 0) ? const Color.fromARGB(255, 49, 114, 51) : const Color.fromARGB(255, 165, 34, 25),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              (service['customer_signature'] != null && service['customer_signature']['sign'] != 0) ? Icons.verified : Icons.error_outline,
                                              color: (service['customer_signature'] != null && service['customer_signature']['sign'] != 0) ? const Color.fromARGB(255, 52, 121, 54) : const Color.fromARGB(255, 160, 32, 23),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                (service['customer_signature'] != null && service['customer_signature']['sign'] != 0)
                                                    ? AppLocalizations.of(context).translate('card_service_customer_signed')
                                                    : AppLocalizations.of(context).translate('card_service_customer_unsigned'),
                                                style: TextStyle(
                                                  color: (service['customer_signature'] != null && service['customer_signature']['sign'] != 0) ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Details Section
                                      
                                      SizedBox(height: 10.h),
                                      _buildServiceInfoRow(context, 'card_service_date', service['date']),
                                      _buildServiceInfoRow(context, 'card_service_visit_type', service['visit_type']),
                                      _buildServiceInfoRow(context, 'card_service_nature_of_complaint', service['nature_of_complaint']),
                                      _buildServiceInfoRow(context, 'card_service_work_details', service['work_details']),
                                      _buildServiceInfoRow(context, 'card_service_parts_replaced', service['parts_replaced']),
                                      _buildServiceInfoRow(context, 'card_service_ICR_no', service['icr_number']),
                                      _buildServiceInfoRow(context, 'card_service_amount_charged', service['amount_charged']),
                                      _buildServiceInfoRow(context, 'card_service_sign_by', service['Signature_By']),
                                      _buildServiceInfoRow(context, 'card_service_sign_at', service['Signature_At'].split("T")[0]),
                                      SizedBox(height: 16.h),

                                      // Signature Info
                                      
                                      if (service['Signature_Image'] != null && service['Signature_Image'].toString().isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8.r),
                                          child: Image.network(
                                            service['Signature_Image'],
                                            height: 150.h,
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Text(
                                                AppLocalizations.of(context).translate('card_signature_load_failed'),
                                                style: TextStyle(color: Colors.red),
                                              );
                                            },
                                          ),
                                        ),

                                      SizedBox(height: 20.h),


                                      

                                      // Action Buttons
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: service['customer_signature'] != null && service['customer_signature']['sign'] != 0
                                            ? TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text(AppLocalizations.of(context).translate('card_service_close')),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () => _showSignConfirmationDialog(context, context, service['id']),
                                                    icon: Icon(Icons.check_circle, color: Colors.white),
                                                    label: Text(AppLocalizations.of(context).translate('card_service_sign')),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Color.fromARGB(255, 55, 99, 174),
                                                      foregroundColor: Colors.white,
                                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8.r),
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Text(AppLocalizations.of(context).translate('card_service_close')),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Color.fromARGB(255, 214, 0, 0),
                                                      foregroundColor: Colors.white,
                                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8.r),
                                                      ),
                                                    )
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );

                      },
                      child: Text('${AppLocalizations.of(context).translate('card_service_no')} ${service['id']} - ${service['date']}'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
