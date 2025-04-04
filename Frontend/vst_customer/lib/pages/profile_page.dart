import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import '../app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final Function(int) onNavigateToIndex; // Callback to update index in IndexPage

  ProfilePage({super.key, required this.onNavigateToIndex});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String _phone = '';
  String _name = '';
  String _customerid = '';
  String _email = '';
  String _address = '';
  String _region = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadLoginInfo();
  }

  Future<void> _loadLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phone = prefs.getString('phone') ?? '9087654321';
      _name = prefs.getString('name') ?? 'User Name';
      _customerid = prefs.getString('customer_id') ?? 'User Name';
      _email = prefs.getString('email') ?? 'user@vst.com';
      _region = prefs.getString('region') ?? 'Default Region';
      _role = prefs.getString('role') ?? 'Error';
      _address = "${prefs.getString('address') ?? "00, Unknown"}\n"
          "${prefs.getString('city') ?? "Unavailable"}, ${prefs.getString('district') ?? "Unavailable"}\n"
          "${prefs.getString('postal_code') ?? "000000"}";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    String fcmToken = prefs.getString('FCM_Token') ?? '';
    await prefs.clear();
    prefs.setString('FCM_Token', fcmToken);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 55, 99, 174),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _name,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$_role - $_customerid',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '+91 $_phone | $_region',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(Icons.email, color: Color.fromARGB(255, 55, 99, 174)),
                        title: Text(AppLocalizations.of(context).translate('profile_email')),
                        subtitle: Text(_email)
                      ),
                      ListTile(
                        leading: Icon(Icons.location_on, color: Color.fromARGB(255, 55, 99, 174)),
                        title: Text(AppLocalizations.of(context).translate('profile_address')),
                        subtitle: Text(_address),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          widget.onNavigateToIndex(1); // Navigate to ServicePage
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 55, 99, 174),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).translate('profile_service_but'),
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).translate('profile_logout_but'),
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
