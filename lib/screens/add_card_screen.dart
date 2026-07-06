import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../widgets/credit_card_widget.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<CreditCardWidgetState> _cardWidgetKey = GlobalKey<CreditCardWidgetState>();
  
  // Form controllers
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  // Focus nodes
  final FocusNode _cvvFocusNode = FocusNode();

  // Card state for preview
  String _cardNumber = '';
  String _cardHolder = '';
  String _expiryDate = '';
  String _cvv = '';
  String _nickname = '';
  int _styleIndex = 0;
  CardBrand _brand = CardBrand.unknown;

  @override
  void initState() {
    super.initState();
    // Watch CVV focus to flip card
    _cvvFocusNode.addListener(_onCvvFocusChange);

    // Listeners to update card preview
    _numberController.addListener(() {
      setState(() {
        final cleanNum = _numberController.text.replaceAll(' ', '');
        _cardNumber = cleanNum;
        _brand = CreditCard.detectBrand(cleanNum);
      });
    });
    _holderController.addListener(() {
      setState(() {
        _cardHolder = _holderController.text;
      });
    });
    _expiryController.addListener(() {
      setState(() {
        _expiryDate = _expiryController.text;
      });
    });
    _cvvController.addListener(() {
      setState(() {
        _cvv = _cvvController.text;
      });
    });
    _nicknameController.addListener(() {
      setState(() {
        _nickname = _nicknameController.text;
      });
    });
  }

  void _onCvvFocusChange() {
    final hasFocus = _cvvFocusNode.hasFocus;
    // We want the card to show back if CVV is focused, and front otherwise.
    _cardWidgetKey.currentState?.setFlip(hasFocus);
  }

  @override
  void dispose() {
    _cvvFocusNode.removeListener(_onCvvFocusChange);
    _cvvFocusNode.dispose();
    
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final newCard = CreditCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardNumber: _cardNumber,
        cardHolder: _cardHolder.isEmpty ? 'CARD HOLDER' : _cardHolder,
        expiryDate: _expiryDate.isEmpty ? 'MM/YY' : _expiryDate,
        cvv: _cvv,
        brand: _brand,
        cardStyleIndex: _styleIndex,
        cardNickname: _nickname.trim().isEmpty ? null : _nickname.trim(),
      );
      Navigator.of(context).pop(newCard);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate dummy CreditCard for preview widget
    final previewCard = CreditCard(
      id: 'preview',
      cardNumber: _cardNumber.isEmpty ? '••••••••••••••••' : _cardNumber,
      cardHolder: _cardHolder.isEmpty ? 'CARD HOLDER' : _cardHolder,
      expiryDate: _expiryDate.isEmpty ? 'MM/YY' : _expiryDate,
      cvv: _cvv.isEmpty ? '•••' : _cvv,
      brand: _brand,
      cardStyleIndex: _styleIndex,
      cardNickname: _nickname.isEmpty ? null : _nickname,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Card',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Live Card Preview
            Center(
              child: SizedBox(
                height: 225,
                child: Hero(
                  tag: 'add_card_hero',
                  child: CreditCardWidget(
                    key: _cardWidgetKey,
                    card: previewCard,
                    showDetails: true,
                    // Keep front initially unless CVV input is focused
                    isFrontInitially: !_cvvFocusNode.hasFocus,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Style Index Picker (Gradients)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHOOSE THEME',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 6,
                      itemBuilder: (context, idx) {
                        final colors = _getThemeColors(idx);
                        final isSelected = _styleIndex == idx;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _styleIndex = idx;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colors[0].withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Form Inputs Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cardholder name
                        _buildInputField(
                          controller: _holderController,
                          label: 'CARDHOLDER NAME',
                          hint: 'e.g. SHAKIR KASMANI',
                          textCapitalization: TextCapitalization.characters,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Cardholder name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Card number
                        _buildInputField(
                          controller: _numberController,
                          label: 'CARD NUMBER',
                          hint: '0000 0000 0000 0000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            CardNumberFormatter(),
                          ],
                          validator: (val) {
                            if (val == null || val.replaceAll(' ', '').isEmpty) {
                              return 'Card number is required';
                            }
                            final clean = val.replaceAll(' ', '');
                            if (clean.length < 15) {
                              return 'Card number must be 15 or 16 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Expiry & CVV Row
                        Row(
                          children: [
                            // Expiry
                            Expanded(
                              child: _buildInputField(
                                controller: _expiryController,
                                label: 'EXPIRY DATE',
                                hint: 'MM/YY',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  ExpiryDateFormatter(),
                                ],
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(val)) {
                                    return 'Use MM/YY';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // CVV
                            Expanded(
                              child: _buildInputField(
                                controller: _cvvController,
                                focusNode: _cvvFocusNode,
                                label: 'CVV',
                                hint: '123',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (val.length < 3) {
                                    return '3-4 digits';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nickname field
                        _buildInputField(
                          controller: _nicknameController,
                          label: 'CARD NICKNAME (OPTIONAL)',
                          hint: 'e.g. Personal Chase, Online Shopping',
                        ),
                        
                        const SizedBox(height: 32),

                        // Action button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.onSurface,
                            foregroundColor: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _saveCard,
                          child: Text(
                            'Save Card Details',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              fontSize: 15,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  List<Color> _getThemeColors(int index) {
    switch (index) {
      case 0: // Purple
        return [const Color(0xFF6A11CB), const Color(0xFF2575FC)];
      case 1: // Red
        return [const Color(0xFFE52D27), const Color(0xFFB31217)];
      case 2: // Midnight
        return [const Color(0xFF0D324D), const Color(0xFF7F5A83)];
      case 3: // Mint Green
        return [const Color(0xFF11998e), const Color(0xFF38ef7d)];
      case 4: // Gold Slate
        return [const Color(0xFF2C3E50), const Color(0xFF000000)];
      case 5: // Deep Blue
        return [const Color(0xFF000428), const Color(0xFF004e92)];
      default:
        return [const Color(0xFF434343), const Color(0xFF000000)];
    }
  }
}

// Custom input formatters for Credit Card inputs

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonSpaceIndex = i + 1;
      if (nonSpaceIndex % 4 == 0 && nonSpaceIndex != text.length) {
        buffer.write(' '); // add a space after every 4th character
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonSlashIndex = i + 1;
      if (nonSlashIndex == 2 && nonSlashIndex != text.length) {
        buffer.write('/'); // add a slash after month digits
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
