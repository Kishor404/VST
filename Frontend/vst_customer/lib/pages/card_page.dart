import 'package:flutter/material.dart';
import 'card_details.dart'; // Import the CardDetailsPage
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'login_page.dart'; 
import '../app_localizations.dart';


class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  CardPageState createState() => CardPageState();
}

class CardPageState extends State<CardPage> {
  String _refreshToken = '';
  String _accessToken = '';
  List<Map<String, dynamic>> cardData = [];
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
    await fetchCards();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _refreshToken = prefs.getString('RT') ?? '';
      _accessToken = prefs.getString('AT') ?? '';
    });
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken.isEmpty) {
      debugPrint("No refresh token found! Logging out...");
      await _handleLogout();
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
        debugPrint("Refresh token is invalid or expired. Logging out...");
        await _handleLogout();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        debugPrint("Refresh token expired! Logging out...");
      } else {
        debugPrint('Error refreshing token: $e');
      }
      await _handleLogout();
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
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
          isLoading = false;
        });
      } else {
        debugPrint("Unexpected response format: ${response.data}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        debugPrint("Access token expired. Refreshing token...");
        await _refreshAccessToken();
        return fetchCards(); // Retry fetching after token refresh
      }

      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching cards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : cardData.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context).translate('card_no_card'),
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: cardData.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Center(
                            child: ServiceCard(
                              data: cardData[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CardDetailsPage(cardData: cardData[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 45),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const ServiceCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 55, 99, 174),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              data['id'].toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 55, 99, 174),
              ),
            ),
          ),
          SizedBox(height: 15),
          Text(
            '${AppLocalizations.of(context).translate('card_customer_id')} ${data['customer_code']}',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            '${AppLocalizations.of(context).translate('card_model')} ${data['model']}',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            '${AppLocalizations.of(context).translate('card_date_of_installation')} ${data['date_of_installation']}',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 25),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color.fromARGB(255, 55, 99, 174),
              minimumSize: Size(200, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(AppLocalizations.of(context).translate('card_view_card')),
          ),
        ],
      ),
    );
  }
}
