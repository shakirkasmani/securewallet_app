import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/credit_card.dart';
import '../widgets/credit_card_widget.dart';
import '../services/secure_storage_service.dart';
import 'add_card_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _revealDetails = false;
  bool _isLoading = true;

  // Key to control card widgets' internal flip states if needed
  final Map<String, GlobalKey<CreditCardWidgetState>> _cardKeys = {};

  final List<CreditCard> _cards = [
    CreditCard(
      id: '1',
      cardNumber: '4532781234569012',
      cardHolder: 'SHAKIR KASMANI',
      expiryDate: '12/29',
      cvv: '348',
      brand: CardBrand.visa,
      cardStyleIndex: 0,
      cardNickname: 'Primary Rewards',
    ),
    CreditCard(
      id: '2',
      cardNumber: '5412759901234567',
      cardHolder: 'SHAKIR KASMANI',
      expiryDate: '08/28',
      cvv: '512',
      brand: CardBrand.mastercard,
      cardStyleIndex: 1,
      cardNickname: 'Business Expense',
    ),
    CreditCard(
      id: '3',
      cardNumber: '378282246310005',
      cardHolder: 'SHAKIR KASMANI',
      expiryDate: '05/30',
      cvv: '9913',
      brand: CardBrand.amex,
      cardStyleIndex: 4,
      cardNickname: 'Corporate Gold',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStoredCards();
  }

  Future<void> _loadStoredCards() async {
    final stored = await SecureStorageService().loadCards();
    if (stored.isEmpty) {
      // First launch: seed secure storage with the preloaded mock cards
      await SecureStorageService().saveCards(_cards);
    } else {
      _cards.clear();
      _cards.addAll(stored);
    }

    // Initialize keys for all loaded cards
    for (var card in _cards) {
      _cardKeys[card.id] = GlobalKey<CreditCardWidgetState>();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewCard(CreditCard card) async {
    setState(() {
      _cards.add(card);
      _cardKeys[card.id] = GlobalKey<CreditCardWidgetState>();
    });
    
    // Encrypt and save updated card list to secure storage
    await SecureStorageService().saveCards(_cards);

    // Scroll to the newly added card at the bottom of the list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Wallet',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        actions: [
          // Security Visibility Toggle in AppBar (Global toggle)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _revealDetails ? Icons.visibility : Icons.visibility_off,
                color: _revealDetails ? const Color(0xFF10B981) : onSurface.withOpacity(0.7),
                size: 20,
              ),
            ),
            tooltip: _revealDetails ? 'Hide details' : 'Show details',
            onPressed: () {
              setState(() {
                _revealDetails = !_revealDetails;
              });
            },
          ),
          // Add Card Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: onSurface, size: 20),
            ),
            onPressed: () async {
              final newCard = await Navigator.of(context).push<CreditCard>(
                MaterialPageRoute(builder: (context) => const AddCardScreen()),
              );
              if (newCard != null) {
                _addNewCard(newCard);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _cards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: CreditCardWidget(
                        key: _cardKeys[card.id],
                        card: card,
                        showDetails: _revealDetails,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off,
              size: 80,
              color: onSurface.withOpacity(0.1),
            ),
            const SizedBox(height: 24),
            Text(
              'No Cards Stored',
              style: GoogleFonts.inter(
                color: onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a card to begin storing your credit cards securely for quick online copying.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: onSurface.withOpacity(0.38),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: onSurface,
                foregroundColor: surface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final newCard = await Navigator.of(context).push<CreditCard>(
                  MaterialPageRoute(builder: (context) => const AddCardScreen()),
                );
                if (newCard != null) {
                  _addNewCard(newCard);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Add Your First Card',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
