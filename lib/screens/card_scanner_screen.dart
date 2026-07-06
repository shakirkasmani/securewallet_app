import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _laserPosition;
  
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _laserPosition = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Default to back camera
        final backCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _startImageStream();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (_isScanning) return; // If already succeeded and popping, skip
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

        final camera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
        final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

        final int bytesPerRow = image.planes.isNotEmpty ? image.planes.first.bytesPerRow : 0;

        final metadata = InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: bytesPerRow,
        );

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: metadata,
        );

        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        _parseCardDetails(recognizedText.text);
      } catch (e) {
        debugPrint("Error processing frame: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _parseCardDetails(String text) {
    // 1. Search for credit card numbers (groups of 13 to 19 digits)
    final numberRegex = RegExp(r'\b(?:\d[ -]*?){13,19}\b');
    final matches = numberRegex.allMatches(text);
    String? foundNumber;
    
    for (var match in matches) {
      final rawNum = match.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (rawNum.length >= 13 && rawNum.length <= 19) {
        foundNumber = rawNum;
        break;
      }
    }

    // 2. Search for Expiry Date (MM/YY or MM/YYYY)
    final expiryRegex = RegExp(r'\b(0[1-9]|1[0-2])\s*/\s*([0-9]{2,4})\b');
    final expiryMatch = expiryRegex.firstMatch(text);
    String? foundExpiry;
    if (expiryMatch != null) {
      final month = expiryMatch.group(1)!;
      var year = expiryMatch.group(2)!;
      if (year.length == 4) {
        year = year.substring(2);
      }
      foundExpiry = '$month/$year';
    }

    // 3. Search for Cardholder Name
    final lines = text.split('\n');
    String? foundHolder;
    final commonKeywords = [
      'VISA', 'MASTERCARD', 'AMEX', 'DISCOVER', 'EXPRESS', 'BANK', 'CARD',
      'DEBIT', 'CREDIT', 'VALID', 'THRU', 'MONTH', 'YEAR', 'GOOD', 'FROM',
      'MEMBER', 'SINCE', 'SECURITY', 'LIMIT', 'PLATINUM', 'GOLD', 'PREMIER'
    ];

    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;

      // Match uppercase alphabetic words (likely to be the cardholder name)
      final isUpperAlpha = RegExp(r'^[A-Z ]+$').hasMatch(cleanLine);
      if (isUpperAlpha) {
        final words = cleanLine.split(' ').where((w) => w.isNotEmpty).toList();
        if (words.length >= 2 && words.length <= 4) {
          bool containsKeyword = false;
          for (var keyword in commonKeywords) {
            if (cleanLine.contains(keyword)) {
              containsKeyword = true;
              break;
            }
          }
          if (!containsKeyword) {
            foundHolder = cleanLine;
            break;
          }
        }
      }
    }

    // If card number is successfully matched, stop scanner and return details!
    if (foundNumber != null) {
      setState(() {
        _isScanning = true;
      });

      _controller?.stopImageStream();

      // Return parsed/scanned card details
      final scannedCardData = {
        'cardNumber': foundNumber,
        'cardHolder': foundHolder ?? 'CARD HOLDER',
        'expiryDate': foundExpiry ?? '12/30',
        'cvv': '123', // CVV needs to be manually entered by user for security
      };

      if (mounted) {
        Navigator.of(context).pop(scannedCardData);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.85;
    final cardHeight = cardWidth / 1.586; // standard aspect ratio

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan Card',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Camera Viewfinder
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 2. Overlay Cut-out Mask
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.65),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    color: Colors.transparent,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Card-shaped stencil border
          Align(
            alignment: Alignment.center,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF10B981), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Laser Sweep Line
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserPosition.value * (cardHeight - 4),
                        left: 4,
                        right: 4,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Instructions overlay text
          Positioned(
            bottom: 80,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isScanning) ...[
                  const CircularProgressIndicator(color: Color(0xFF10B981)),
                  const SizedBox(height: 16),
                  Text(
                    'Extracting card details...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Color(0xFF10B981),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Align your card in the frame to scan...',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
