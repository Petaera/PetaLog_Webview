import 'package:flutter/material.dart';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp()); // ✅ Ensure MyApp is used correctly
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // ✅ Start with SplashScreen
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // ✅ Capture context before async gap
    final BuildContext currentContext = context;

    // Navigate to WebViewScreen after 2 seconds
    Timer(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(currentContext).pushReplacement(
          MaterialPageRoute(builder: (context) => WebViewScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 255, 255), // Black
              // Color(0xFF2E2E2E), // Dark Gray
              Color.fromARGB(255, 255, 255, 255), // Light Gray
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Image.asset(
              'assets/petalog.png', // ✅ Replace with your app icon
              width: 450,
              height: 450,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ✅ WebView Screen with Network Error Handling
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  WebViewScreenState createState() => WebViewScreenState();
}

class WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isError = false; // ✅ Track if there's an error
  bool _isLoading = true; // ✅ Track loading state

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Add a small delay to ensure platform is ready
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          _controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000))
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (url) {
                  if (mounted) {
                    setState(() {
                      _isError = false;
                      _isLoading = true;
                    });
                  }
                },
                onPageFinished: (url) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                onWebResourceError: (error) {
                  if (mounted) {
                    setState(() {
                      _isError =
                          true; // ✅ Show error screen if network error occurs
                      _isLoading = false;
                    });
                  }
                },
              ),
            )
            ..loadRequest(Uri.parse('https://log.petaera.com'));
        } catch (e) {
          if (mounted) {
            setState(() {
              _isError = true;
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  Future<bool> _onBackPressed() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          bool shouldClose = await _onBackPressed();

          if (shouldClose && mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).maybePop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: _isError
              ? _buildErrorScreen()
              : _isLoading
                  ? _buildLoadingScreen()
                  : WebViewWidget(controller: _controller),
        ),
      ),
    );
  }

  // ✅ Error Screen Widget
  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Network Error",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text("Check your internet connection and try again."),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isError = false;
                _isLoading = true;
              });
              _initializeWebView(); // ✅ Reinitialize WebView on retry
            },
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }

  // ✅ Loading Screen Widget
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Loading..."),
        ],
      ),
    );
  }
}
