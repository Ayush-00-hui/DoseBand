import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class LiveQrScannerScreen extends StatefulWidget {
  const LiveQrScannerScreen({super.key});

  @override
  State<LiveQrScannerScreen> createState() => _LiveQrScannerScreenState();
}

class _LiveQrScannerScreenState extends State<LiveQrScannerScreen> with TickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isDetecting = true;
  bool _success = false;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  late AnimationController _successController;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successOpacityAnimation;

  @override
  void initState() {
    super.initState();
    // Scanning line animation (up and down)
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Success checkmark animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _successScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    
    _successOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _successController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isDetecting) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null) {
        setState(() {
          _isDetecting = false;
          _success = true;
        });
        
        // Stop scanning line, show success
        _scanLineController.stop();
        _controller.stop();
        _successController.forward();

        // Wait for animation to finish, then return the scanned value
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.pop(context, rawValue);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cutout size for the scanner
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            overlayBuilder: (context, constraints) {
              return Stack(
                children: [
                  // Darkened background with a clear cutout in the center
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.7),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Center(
                          child: Container(
                            width: scanAreaSize,
                            height: scanAreaSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Viewfinder Frame & Animations
                  Center(
                    child: SizedBox(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      child: Stack(
                        children: [
                          // Corner Brackets
                          if (!_success) ...[
                            _buildCorner(Alignment.topLeft),
                            _buildCorner(Alignment.topRight),
                            _buildCorner(Alignment.bottomLeft),
                            _buildCorner(Alignment.bottomRight),
                          ],
                          
                          // Scanning Line Animation
                          if (!_success)
                            AnimatedBuilder(
                              animation: _scanLineAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanLineAnimation.value * (scanAreaSize - 4),
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppTheme.safetyOrange,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.safetyOrange.withOpacity(0.6),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Success Checkmark Animation
                          if (_success)
                            Center(
                              child: AnimatedBuilder(
                                animation: _successController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _successOpacityAnimation.value,
                                    child: Transform.scale(
                                      scale: _successScaleAnimation.value,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppTheme.safeGreen,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.safeGreen.withOpacity(0.5),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top Bar UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _controller.torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _controller.toggleTorch();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Helper Text Bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _success ? 'Code Detected!' : 'Align QR code within the frame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    const double length = 30.0;
    const double thickness = 4.0;
    const Color color = Colors.white;
    const double radius = 10.0;

    return Align(
      alignment: alignment,
      child: Container(
        width: length,
        height: length,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            bottom: alignment.y > 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            left: alignment.x < 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            right: alignment.x > 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft ? const Radius.circular(radius) : Radius.zero,
            topRight: alignment == Alignment.topRight ? const Radius.circular(radius) : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft ? const Radius.circular(radius) : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight ? const Radius.circular(radius) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
