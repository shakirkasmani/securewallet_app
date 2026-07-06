import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../services/notification_service.dart';

class CreditCardWidget extends StatefulWidget {
  final CreditCard card;
  final bool showDetails;
  final VoidCallback? onTap;
  final bool isFrontInitially;
  final bool showActionButtons;

  const CreditCardWidget({
    super.key,
    required this.card,
    this.showDetails = false,
    this.onTap,
    this.isFrontInitially = true,
    this.showActionButtons = true,
  });

  @override
  State<CreditCardWidget> createState() => CreditCardWidgetState();
}

class CreditCardWidgetState extends State<CreditCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _isFront = widget.isFrontInitially;
    _showDetails = widget.showDetails;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    if (!_isFront) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant CreditCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showDetails != widget.showDetails) {
      setState(() {
        _showDetails = widget.showDetails;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleFlip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void setFlip(bool showBack) {
    if (showBack && _isFront) {
      _controller.forward();
      setState(() {
        _isFront = false;
      });
    } else if (!showBack && !_isFront) {
      _controller.reverse();
      setState(() {
        _isFront = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        toggleFlip();
        if (widget.onTap != null) widget.onTap!();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final transformValue = _animation.value * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(transformValue),
            alignment: Alignment.center,
            child: transformValue < pi / 2
                ? _buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  // --- Front Side UI ---
  Widget _buildFront() {
    final style = _getCardStyle(widget.card.cardStyleIndex);

    return Container(
      width: 340,
      height: 215,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: style.gradient,
        boxShadow: [
          BoxShadow(
            color: style.shadowColor.withAlpha((255 * 0.4).toInt()),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.15).toInt()),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Glassmorphic shimmer reflection overlay
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha((255 * 0.05).toInt()),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha((255 * 0.03).toInt()),
                ),
              ),
            ),
            
            // Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Brand & Nickname & Chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.card.cardNickname != null && widget.card.cardNickname!.isNotEmpty)
                              Text(
                                widget.card.cardNickname!.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withAlpha((255 * 0.6).toInt()),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            const SizedBox(height: 4),
                            _buildBrandLogo(widget.card.brand),
                          ],
                        ),
                      ),
                      if (widget.showActionButtons)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCardActionIcon(
                              icon: _showDetails ? Icons.visibility : Icons.visibility_off,
                              onTap: () {
                                setState(() {
                                  _showDetails = !_showDetails;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildCardActionIcon(
                              icon: Icons.copy,
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: widget.card.cardNumber));
                              
                              await NotificationService().showNotification(
                                id: widget.card.id.hashCode,
                                title: 'Card details copied',
                                body: 'Expiry: ${widget.card.expiryDate} | CVV: ${widget.card.cvv}',
                              );
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Number copied! Expiry & CVV sent to notifications.',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF1E1E24),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildCardChip(),
                        ],
                      ),
                    ],
                  ),

                  // Middle Row: Card Number
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _showDetails
                          ? widget.card.formattedCardNumber
                          : widget.card.maskedCardNumber,
                      style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  // Bottom Row: Holder & Expiry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARD HOLDER',
                              style: GoogleFonts.inter(
                                color: Colors.white.withAlpha((255 * 0.5).toInt()),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.card.cardHolder.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'EXPIRES',
                            style: GoogleFonts.inter(
                              color: Colors.white.withAlpha((255 * 0.5).toInt()),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.card.expiryDate,
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Back Side UI ---
  Widget _buildBack() {
    final style = _getCardStyle(widget.card.cardStyleIndex);

    return Container(
      width: 340,
      height: 215,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: style.gradient,
        boxShadow: [
          BoxShadow(
            color: style.shadowColor.withAlpha((255 * 0.3).toInt()),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.15).toInt()),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Magnetic Stripe
            Container(
              width: double.infinity,
              height: 44,
              color: Colors.black.withAlpha((255 * 0.85).toInt()),
            ),
            const SizedBox(height: 18),
            // Signature & CVV Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // White signature block
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((255 * 0.8).toInt()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        widget.card.cardHolder.toLowerCase(),
                        style: GoogleFonts.caveat(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // CVV box
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _showDetails ? widget.card.cvv : '•••',
                        style: GoogleFonts.spaceMono(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Holographic strip / info
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AUTHORIZED SIGNATURE',
                    style: GoogleFonts.inter(
                      color: Colors.white.withAlpha((255 * 0.4).toInt()),
                      fontSize: 8,
                      letterSpacing: 1.0,
                    ),
                  ),
                  _buildBrandLogo(widget.card.brand),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers for Card Drawing ---

  Widget _buildCardActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((255 * 0.15).toInt()),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withAlpha((255 * 0.2).toInt()),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildCardChip() {
    return Container(
      width: 44,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF3E0B5),
            const Color(0xFFD4AF37),
            const Color(0xFFA67C00),
            const Color(0xFFD4AF37),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.1).toInt()),
          width: 0.5,
        ),
      ),
      child: CustomPaint(
        painter: ChipCircuitPainter(),
      ),
    );
  }

  Widget _buildBrandLogo(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return Text(
          'VISA',
          style: GoogleFonts.spectral(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        );
      case CardBrand.mastercard:
        return SizedBox(
          width: 42,
          height: 25,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 17,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      case CardBrand.amex:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0070CD),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'AMEX',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        );
      case CardBrand.discover:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DISCOVER',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      default:
        return Text(
          'CARD',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        );
    }
  }

  _CardThemeStyle _getCardStyle(int index) {
    switch (index) {
      case 0: // Cosmic Purple
        return _CardThemeStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF2575FC),
        );
      case 1: // Solar Flare
        return _CardThemeStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFE52D27), Color(0xFFB31217)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFFE52D27),
        );
      case 2: // Ocean Glass
        return _CardThemeStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D324D), Color(0xFF7F5A83)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF7F5A83),
        );
      case 3: // Emerald Mint
        return _CardThemeStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF38ef7d),
        );
      case 4: // Royal Gold / Luxury Matte
        return _CardThemeStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF2C3E50),
        );
      case 5: // Carbon Cyberpunk
        return _CardThemeStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF000428), Color(0xFF004e92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: const Color(0xFF004e92),
        );
      default:
        return _CardThemeStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF434343), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: Colors.black,
        );
    }
  }
}

class _CardThemeStyle {
  final LinearGradient gradient;
  final Color shadowColor;

  _CardThemeStyle({required this.gradient, required this.shadowColor});
}

// Paints gold metal contact circuit lines on the chip
class ChipCircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal split line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw vertical split lines
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.65, 0),
      Offset(size.width * 0.65, size.height),
      paint,
    );

    // Draw circular chip connection loop
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * 0.4,
          height: size.height * 0.5,
        ),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
