import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_details.dart';
import 'data.dart';
import 'login_page.dart';
import '../app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtils

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
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
    await fetchProducts();
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
      await _logout();
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
        debugPrint("Refresh token expired or invalid. Logging out...");
        await _logout();
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      await _logout(); // Logout on error (e.g., expired refresh token)
    }
  }

  Future<void> fetchProducts() async {
    if (_accessToken.isEmpty) {
      debugPrint("No access token available. Cannot fetch products.");
      return;
    }

    try {
      final response = await _dio.get(
        '${Data.baseUrl}/products/',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        }),
      );

      setState(() {
        products = response.data;
        isLoading = false;
      });
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        debugPrint("Access token expired. Refreshing token...");
        await _refreshAccessToken();
        return fetchProducts(); // Retry fetching after token refresh
      }

      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtils
    ScreenUtil.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w), // Use ScreenUtil for padding
                  child: Text(
                    AppLocalizations.of(context).translate('product_title'),
                    style: TextStyle(
                      fontSize: 20.sp, // Use ScreenUtil for font size
                      color: Color.fromARGB(255, 55, 99, 174),
                    ),
                  ),
                ),
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context).translate('product_no_product'),
                            style: TextStyle(fontSize: 18.sp, color: Colors.grey), // Use ScreenUtil for font size
                          ),
                        )
                      : SafeArea(
                          child: Padding(
                            padding: EdgeInsets.all(30.w), // Use ScreenUtil for padding
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                bool isLastColumn = (index + 1) % 2 == 0;
                                bool isLastRow = index >= products.length - 2;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: isLastColumn
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: Color.fromARGB(255, 131, 131, 131),
                                              width: 1.0),
                                      bottom: isLastRow
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: Color.fromARGB(255, 131, 131, 131),
                                              width: 1.0),
                                    ),
                                  ),
                                  child: ProductTile(
                                    productName: product['name'],
                                    productImage: product['image'],
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailsPage(
                                            productName: product['name'],
                                            productImg: product['image'],
                                            productDet: product['details'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final String productName;
  final String productImage;
  final VoidCallback onTap;

  const ProductTile({
    required this.productName,
    required this.productImage,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(20.w), // Use ScreenUtil for padding
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.h), // Use ScreenUtil for vertical padding
                child: Image.network(
                  productImage,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
            Text(
              productName,
              style: TextStyle(
                fontSize: 15.sp, // Use ScreenUtil for font size
                color: Color.fromARGB(255, 55, 99, 174),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
