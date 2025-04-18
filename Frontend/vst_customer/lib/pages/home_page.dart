import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';  // Add this import
import 'contact.dart';
import 'data.dart';
import 'help.dart';
import 'package:dio/dio.dart';
import 'settings.dart';
import '../app_localizations.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigateToIndex;
  const HomePage({super.key, required this.onNavigateToIndex});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final Dio _dio = Dio();
  List<String> quotes = [
    "I will love the light for it shows me the way, yet I will endure the darkness because it shows me the stars.",
    "OG Mandino"
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      Response response = await _dio.get('${Data.baseUrl}/media/data.json');
      if (response.statusCode == 200) {
        setState(() {
          quotes = List<String>.from(response.data['quotes']);
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ScreenUtil for responsive screen width
    double screenWidth = ScreenUtil().screenWidth;

    final List<Map<String, dynamic>> buttonData = [
      {'icon': Icons.construction, 'label': AppLocalizations.of(context).translate('home_service'), 'onTap': () => widget.onNavigateToIndex(1)},
      {'icon': Icons.phone, 'label': AppLocalizations.of(context).translate('home_contact'), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContactPage()))},
      {'icon': Icons.article, 'label': AppLocalizations.of(context).translate('home_card'), 'onTap': () => widget.onNavigateToIndex(3)},
      {'icon': Icons.settings, 'label': AppLocalizations.of(context).translate('home_setting'), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()))},
      {'icon': Icons.notifications, 'label': AppLocalizations.of(context).translate('home_alert'), 'onTap': () => print('Alerts tapped')},
      {'icon': Icons.shopping_bag, 'label': AppLocalizations.of(context).translate('home_product'), 'onTap': () => widget.onNavigateToIndex(2)},
      {'icon': Icons.help, 'label': AppLocalizations.of(context).translate('home_help'), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => HelpPage()))},
      {'icon': Icons.person, 'label': AppLocalizations.of(context).translate('home_profile'), 'onTap': () => widget.onNavigateToIndex(4)},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16.0.sp), // Use screen scaling for padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Use ScreenUtil for responsive sizing
            SizedBox(
              height: screenWidth * 0.8 * 9 / 16,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9, initialPage: 1000),
                itemBuilder: (context, index) {
                  int actualIndex = index % 3;
                  return Container(
                    width: screenWidth * 0.9,
                    margin: EdgeInsets.symmetric(horizontal: 8.sp),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.sp),
                      image: DecorationImage(
                        image: NetworkImage('${Data.baseUrl}/media/Banners/banner$actualIndex.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 50.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) => _buildIconButton(screenWidth, buttonData[index])),
            ),
            SizedBox(height: 30.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) => _buildIconButton(screenWidth, buttonData[index + 4])),
            ),
            SizedBox(height: 50.sp),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.sp),
                ),
                child: Center(
                  child: SizedBox(
                    width: screenWidth * 0.8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '"${quotes.isNotEmpty ? quotes[0] : AppLocalizations.of(context).translate('home_loading')}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic, color: Colors.black87),
                        ),
                        SizedBox(height: 8.sp),
                        Text(
                          '- ${quotes.length > 1 ? quotes[1] : ""}',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(double screenWidth, Map<String, dynamic> data) {
    return InkWell(
      onTap: data['onTap'],
      borderRadius: BorderRadius.circular(8.sp),
      child: Container(
        width: screenWidth / 6,
        height: screenWidth / 6,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 55, 99, 174),
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data['icon'], size: screenWidth / 15.sp, color: Colors.white70),
            SizedBox(height: 8.sp),
            Text(data['label'], style: TextStyle(fontSize: screenWidth / 28.sp, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
