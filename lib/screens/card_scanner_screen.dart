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
          imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          
          // Introduce a 500ms delay to allow the camera preview texture to register
          // and display in the engine before initiating the image stream.
          // This avoids native thread deadlocks/freezes on initial startup.
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _startImageStream();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  DateTime? _lastProcessedTime;

  // Silent automatic scanning loop using live camera image stream (avoids iOS shutter sound)
  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (_isScanning) return; // If already succeeded and popping, skip

      final now = DateTime.now();
      if (_lastProcessedTime != null && now.difference(_lastProcessedTime!).inMilliseconds < 1000) {
        return; // Drop frames to prevent UI thread saturation and freeze
      }

      if (_isProcessing) return;
      _isProcessing = true;
      _lastProcessedTime = now;

      try {
        final Uint8List bytes;
        final InputImageFormat inputImageFormat;
        
        if (Platform.isIOS) {
          bytes = image.planes.first.bytes;
          inputImageFormat = InputImageFormat.bgra8888;
        } else {
          // Convert Android YUV_420_888 to NV21 bytes to satisfy native Android plugin converter
          bytes = _convertYUV420ToNV21(image);
          inputImageFormat = InputImageFormat.nv21;
        }

        final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

        final camera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
        
        final InputImage inputImage;
        if (Platform.isIOS) {
          // On iOS, we use the bitmap constructor which handles copying raw image bytes safely
          // into CoreGraphics contexts, completely bypassing CoreVideo CVPixelBuffer lock-state crashes.
          inputImage = InputImage.fromBitmap(
            bitmap: bytes,
            width: image.width,
            height: image.height,
            rotation: camera.sensorOrientation,
          );
        } else {
          final int bytesPerRow = image.planes.isNotEmpty ? image.planes.first.bytesPerRow : 0;
          final metadata = InputImageMetadata(
            size: imageSize,
            rotation: imageRotation,
            format: inputImageFormat,
            bytesPerRow: bytesPerRow,
          );
          inputImage = InputImage.fromBytes(
            bytes: bytes,
            metadata: metadata,
          );
        }

        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        _parseCardDetails(recognizedText.text);
      } catch (e) {
        debugPrint("Error processing stream frame: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  // Converts Android YUV_420_888 frame structure into raw NV21 bytes.
  // The google_mlkit_commons native converter on Android only supports NV21 (17) or YV12 (842094169).
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = width * height;
    final nv21 = Uint8List(numPixels + (numPixels ~/ 2));

    // 1. Copy Y plane
    int nv21Idx = 0;
    if (yPlane.bytesPerRow == width) {
      nv21.setRange(0, numPixels, yBuffer);
      nv21Idx = numPixels;
    } else {
      int yIdx = 0;
      for (int row = 0; row < height; row++) {
        nv21.setRange(nv21Idx, nv21Idx + width, yBuffer.sublist(yIdx, yIdx + width));
        nv21Idx += width;
        yIdx += yPlane.bytesPerRow;
      }
    }

    // 2. Interleave V and U bytes (NV21 is Y-V-U-V-U...)
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final int uvWidth = width ~/ 2;
    final int uvHeight = height ~/ 2;

    for (int row = 0; row < uvHeight; row++) {
      final int uRowOffset = row * uvRowStride;
      final int vRowOffset = row * vPlane.bytesPerRow;
      final int vPixelStride = vPlane.bytesPerPixel ?? 1;
      
      for (int col = 0; col < uvWidth; col++) {
        final int uIdx = uRowOffset + col * uvPixelStride;
        final int vIdx = vRowOffset + col * vPixelStride;
        
        if (vIdx < vBuffer.length && nv21Idx < nv21.length) {
          nv21[nv21Idx++] = vBuffer[vIdx];
        }
        if (uIdx < uBuffer.length && nv21Idx < nv21.length) {
          nv21[nv21Idx++] = uBuffer[uIdx];
        }
      }
    }

    return nv21;
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
    _isScanning = true;
    
    // Explicitly stop the image stream before disposing the controller to prevent native thread leaks
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
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
