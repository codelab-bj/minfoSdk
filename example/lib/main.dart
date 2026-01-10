import 'package:flutter/material.dart';
import 'dart:math' as math;
// 1. Importation de ton package
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/minfo_web_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minfo iFrame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFAAFF89),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MinfoIframePage(),
    );
  }
}

class MinfoIframePage extends StatefulWidget {
  const MinfoIframePage({Key? key}) : super(key: key);

  @override
  State<MinfoIframePage> createState() => _MinfoIframePageState();
}

class _MinfoIframePageState extends State<MinfoIframePage>
    with TickerProviderStateMixin {

  // 2. Initialisation du SDK
  final MinfoSDK _minfoSDK = MinfoSDK.instance;

  ConnectMode currentConnectMode = ConnectMode.NO_CONNECT_MODE;
  String? brandLogoUrl;
  bool isAuthorized = true;

  late AnimationController _audioAnimationController;
  late Animation<double> animation;

  static const double _connectButtonSize = 60.0;
  static const double _connectButtonSizeSelected = 70.0;
  static const double featureWidgetHeight = 60;
  static const double featureWidgetWidth = 60;

  static const Color minfoGreen = Color(0xFFAAFF89);
  static const Color minfoGray = Color(0xFFa3a3a3);

  @override
  void initState() {
    super.initState();
    _audioAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    animation = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _audioAnimationController, curve: Curves.bounceOut),
    );

    _audioAnimationController.forward();
  }

  // 3. Fonction pour ouvrir la WebView du SDK
  void _openMinfoCampaign(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MinfoWebView(
          campaignUrl: url,

        ),
      ),
    );
  }

  void _startAudioAnimation({int duration = 1}) {
    _audioAnimationController.stop();
    _audioAnimationController.reset();
    _audioAnimationController.repeat(period: Duration(seconds: duration));
  }

  void _toggleConnectMode(ConnectMode mode) {
    setState(() {
      if (currentConnectMode == mode) {
        currentConnectMode = ConnectMode.NO_CONNECT_MODE;
        _audioAnimationController.stop();
      } else {
        currentConnectMode = mode;
        _startAudioAnimation(duration: 2);

        // Simulation : Si on active le mode Audio, on affiche une info
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AudioQR Listening: ${mode.name}')),
        );
      }
    });
  }

  @override
  void dispose() {
    _audioAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: !isAuthorized ? _buildUnauthorizedView() : _buildMainContent(),
    );
  }

  Widget _buildUnauthorizedView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: minfoGreen),
          const SizedBox(height: 24),
          const Text('Access Denied', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _buildTopLogo(),
                _buildQrButton(constraints),
                _buildMainConnectButton(),
                _buildConnectModeText(),
                _buildPoweredByMinfo(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopLogo() {
    return Positioned(
      top: 16,
      child: _buildPlaceholderLogo(text: 'Minfo SDK Test', color: minfoGreen),
    );
  }

  // 4. Intégration du clic sur le bouton QR
  Widget _buildQrButton(BoxConstraints constraints) {
    return Positioned(
      left: constraints.constrainWidth() / 2 - featureWidgetWidth / 2,
      top: MediaQuery.of(context).size.height / 5,
      child: InkWell(
        onTap: () {
          // Action réelle : On lance une campagne de test via ta WebView
          _openMinfoCampaign("https://minfo.com");
        },
        child: SizedBox(
          height: featureWidgetHeight,
          width: featureWidgetWidth,
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(featureWidgetWidth),
            color: minfoGreen,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, size: 20, color: minfoGray),
                Text('QR', style: TextStyle(color: minfoGray, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainConnectButton() {
    return Center(
      child: GestureDetector(
        onTap: () => _toggleConnectMode(ConnectMode.SINGLE_CONNECT_MODE),
        onLongPress: () => _toggleConnectMode(ConnectMode.MULTI_CONNECT_MODE),
        child: _buildAnimatedButton(),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    return currentConnectMode == ConnectMode.NO_CONNECT_MODE
        ? _buildInactiveButton()
        : _buildActiveButton();
  }

  Widget _buildInactiveButton() {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: minfoGreen, width: 2)),
      padding: const EdgeInsets.all(12),
      child: const Icon(Icons.mic_off, size: _connectButtonSize, color: minfoGreen),
    );
  }

  Widget _buildActiveButton() {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all((10 - animation.value).abs() * (currentConnectMode == ConnectMode.MULTI_CONNECT_MODE ? 2 : 1)),
          decoration: _pulsingDecoration(animation.value.abs().clamp(0.2, 0.6)),
          child: _buildConnectButtonIcon(),
        );
      },
    );
  }

  BoxDecoration _pulsingDecoration(double opacity) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: minfoGreen.withOpacity(opacity),
    );
  }

  Widget _buildConnectButtonIcon() {
    return Container(
      height: _connectButtonSizeSelected,
      width: _connectButtonSizeSelected,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: minfoGreen),
      child: const Icon(Icons.mic, color: Colors.white, size: 40),
    );
  }

  Widget _buildConnectModeText() {
    if (currentConnectMode == ConnectMode.NO_CONNECT_MODE) return const SizedBox.shrink();
    return Positioned(
      bottom: 120,
      child: Text(
        currentConnectMode == ConnectMode.SINGLE_CONNECT_MODE ? "Single Connect" : "Multi Connect",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: minfoGreen),
      ),
    );
  }

  Widget _buildPoweredByMinfo() {
    return Positioned(
      bottom: 16,
      child: _buildPlaceholderLogo(text: 'Powered by Minfo', color: minfoGreen, fontSize: 10),
    );
  }

  Widget _buildPlaceholderLogo({required String text, required Color color, double fontSize = 16}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
    );
  }
}

enum ConnectMode { NO_CONNECT_MODE, SINGLE_CONNECT_MODE, MULTI_CONNECT_MODE }