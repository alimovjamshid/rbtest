import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late WebViewController controller;
  bool isLoading = true; // Yuklanish holati
  bool initialLoading = true; // Faqat birinchi yuklanishda ko‘rsatish uchun
  bool hasInternet = true; // Internet mavjudligini tekshirish

  @override
  void initState() {
    super.initState();
    checkInternetConnection();
    _initWebView();
  }

  // WebViewni sozlash va yuklashni boshlash
  void _initWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (initialLoading) {
              // Faqat dastlabki yuklashda yuklanish indikatorini ko‘rsatish
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false; // Yuklash tugadi
              initialLoading = false; // Endi loading faqat bir marta ishlaydi
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false; // Yuklash xatosi
              hasInternet = false; // Internet yo‘q holatiga tushish
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://rbtest.uz/mobile'));
  }

  // Internetni tekshirish
  Future<void> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        hasInternet = false; // Internet yo‘q
      });
    } else {
      setState(() {
        hasInternet = true; // Internet bor
      });
    }
  }

  // Sahifani qayta yuklash uchun
  void retryLoading() {
    checkInternetConnection(); // Internet qayta tekshirish
    if (hasInternet) {
      controller.reload(); // Internet mavjud bo‘lsa, sahifani qayta yuklash
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran o‘lchamlarini olish
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: hasInternet
              ? Stack(
            children: [
              WebViewWidget(controller: controller), // WebView sahifasini yuklash
              if (isLoading && initialLoading) // Faqat dastlab yuklanganda ko‘rsatish
                Positioned.fill(
                  child: Container(
                    width: screenWidth, // Ekran bo‘ylab to‘liq
                    height: screenHeight, // Ekran balandligida
                    color: Color(0xFF0F5354), // Orqa fon rangi
                    child: Center( // Tasvir markazda
                      child: Image.asset(
                        'assets/loading_images.png', // Loading tasvirini joylash
                        fit: BoxFit.contain, // O‘lchamini saqlash
                      ),
                    ),
                  ),
                ),
            ],
          )
              : NoInternetPage(retryLoading: retryLoading), // Internet bo‘lmaganda sahifa
        ),
      ),
    );
  }
}

// Internet bo‘lmaganda ko‘rsatiladigan sahifa
class NoInternetPage extends StatelessWidget {
  final VoidCallback retryLoading;

  const NoInternetPage({Key? key, required this.retryLoading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 100, color: Colors.grey), // No Internet Icon
          SizedBox(height: 20),
          Text(
            'Internet yo\'q yoki zaif',
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: retryLoading,
            child: Text('Sahifani yangilash'), // Retry button
          ),
        ],
      ),
    );
  }
}
