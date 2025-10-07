import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/models/therapy_content.dart';
import '../providers/therapy_provider.dart';
import '../../../../core/utils/logger.dart';

class AACTherapyScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const AACTherapyScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<AACTherapyScreen> createState() => _AACTherapyScreenState();
}

class _AACTherapyScreenState extends ConsumerState<AACTherapyScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // State
  final List<TherapyContent> _selectedSymbols = [];
  String _selectedCategory = 'all';
  bool _isSpeaking = false;
  int _maxSymbols = 10;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTTS();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage("id-ID");
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = true);
          _pulseController.repeat(reverse: true);
        }
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
          _pulseController.stop();
          _pulseController.reset();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() => _isSpeaking = false);
          _pulseController.stop();
        }
        AppLogger.error('TTS Error: $msg');
      });

      if (Theme.of(context).platform == TargetPlatform.android) {
        var voices = await _flutterTts.getVoices;
        AppLogger.info('Available voices: $voices');

        var indonesianVoice = voices.firstWhere(
          (voice) =>
              voice['locale'].toString().startsWith('id') ||
              voice['name'].toString().toLowerCase().contains('indonesia'),
          orElse: () => voices.first,
        );

        if (indonesianVoice != null) {
          await _flutterTts.setVoice({
            "name": indonesianVoice['name'],
            "locale": indonesianVoice['locale']
          });
          AppLogger.info('Using voice: ${indonesianVoice['name']}');
        }
      }

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        await _flutterTts.setVoice({"name": "id-ID-language", "locale": "id-ID"});
      }

      AppLogger.success('TTS initialized with Indonesian voice');
    } catch (e) {
      AppLogger.error('Error initializing TTS: $e');
    }
  }

  void _addSymbol(TherapyContent content) {
    if (_selectedSymbols.length >= _maxSymbols) {
      _showModernSnackBar(
        'Maximum $_maxSymbols symbols reached',
        Icons.warning_rounded,
        Colors.orange,
      );
      return;
    }

    setState(() => _selectedSymbols.add(content));
    HapticFeedback.lightImpact();

    _showModernSnackBar(
      '"${content.targetWord}" added',
      Icons.check_circle_rounded,
      const Color(0xFF9C27B0),
    );
  }

  void _removeSymbol(int index) {
    setState(() => _selectedSymbols.removeAt(index));
    HapticFeedback.mediumImpact();
  }

  void _clearAll() {
    setState(() => _selectedSymbols.clear());
    HapticFeedback.heavyImpact();
    
    _showModernSnackBar(
      'All symbols cleared',
      Icons.delete_sweep_rounded,
      Colors.red,
    );
  }

  Future<void> _speak() async {
    if (_selectedSymbols.isEmpty || _isSpeaking) return;

    final sentence = _selectedSymbols.map((s) => s.targetWord).join(' ');
    HapticFeedback.mediumImpact();

    try {
      await _flutterTts.speak(sentence);
    } catch (e) {
      AppLogger.error('Error speaking: $e');
      _showModernSnackBar(
        'Unable to speak',
        Icons.error_outline_rounded,
        Colors.red,
      );
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentAsync = ref.watch(therapyContentProvider(widget.categoryId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: false,
      appBar: _buildModernAppBar(isDark),
      body: Column(
        children: [
          _buildModernCategoryTabs(isDark),
          Expanded(
            child: contentAsync.when(
              data: (contents) => _buildSymbolGrid(contents, isDark),
              loading: () => _buildLoadingState(isDark),
              error: (error, stack) => _buildErrorState(error.toString(), isDark),
            ),
          ),
          _buildModernSentenceBuilder(isDark),
        ],
      ),
      floatingActionButton: _selectedSymbols.isNotEmpty
          ? _buildModernFABs(isDark)
          : null,
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildModernAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.categoryName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            'AAC Communication',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            onPressed: () => _showModernInfoDialog(isDark),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // CATEGORY TABS
  // ============================================================================

  Widget _buildModernCategoryTabs(bool isDark) {
    final categories = [
      {'id': 'all', 'name': 'All', 'icon': Icons.apps_rounded},
      {'id': 'makan', 'name': 'Food', 'icon': Icons.restaurant_rounded},
      {'id': 'minum', 'name': 'Drink', 'icon': Icons.local_drink_rounded},
      {'id': 'emosi', 'name': 'Emotion', 'icon': Icons.sentiment_satisfied_rounded},
      {'id': 'aktivitas', 'name': 'Activity', 'icon': Icons.directions_run_rounded},
      {'id': 'tempat', 'name': 'Place', 'icon': Icons.place_rounded},
    ];

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                      )
                    : null,
                color: !isSelected
                    ? (isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100)
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF9C27B0)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedCategory = category['id'] as String);
                    HapticFeedback.selectionClick();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // SYMBOL GRID
  // ============================================================================

  Widget _buildSymbolGrid(List<TherapyContent> contents, bool isDark) {
    final filteredContents = _selectedCategory == 'all'
        ? contents
        : contents
            .where((c) =>
                c.title.toLowerCase().contains(_selectedCategory.toLowerCase()))
            .toList();

    if (filteredContents.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: filteredContents.length,
        itemBuilder: (context, index) {
          return _buildModernSymbolCard(filteredContents[index], isDark, index);
        },
      ),
    );
  }

  Widget _buildModernSymbolCard(TherapyContent content, bool isDark, int index) {
    final imageUrl = content.imageUrl ?? '';
    final isSelected = _selectedSymbols.contains(content);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9C27B0)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF9C27B0).withOpacity(0.3)
                  : (isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15)),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _addSymbol(content),
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background gradient circle
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF9C27B0).withOpacity(0.1),
                          const Color(0xFF9C27B0).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon/Image container
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF9C27B0).withOpacity(0.2),
                              const Color(0xFF7B1FA2).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF9C27B0).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image_not_supported_rounded,
                                      size: 32,
                                      color: Color(0xFF9C27B0),
                                    );
                                  },
                                )
                              : Icon(
                                  _getIconForWord(content.targetWord),
                                  size: 32,
                                  color: const Color(0xFF9C27B0),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Symbol text
                      Text(
                        content.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Target word badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          content.targetWord,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected indicator
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // SENTENCE BUILDER
  // ============================================================================

  Widget _buildModernSentenceBuilder(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'My Sentence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 14,
                        color: Color(0xFF9C27B0),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedSymbols.length}/$_maxSymbols',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Symbols list
          Expanded(
            child: _selectedSymbols.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 32,
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap symbols to build your sentence',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _selectedSymbols.length,
                    itemBuilder: (context, index) {
                      final symbol = _selectedSymbols[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9C27B0).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                symbol.targetWord,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeSymbol(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================================
  // FABs
  // ============================================================================

  Widget _buildModernFABs(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Speak button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isSpeaking ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isSpeaking
                        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                        : [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSpeaking
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF9C27B0))
                          .withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _speak,
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: Icon(
                        _isSpeaking
                            ? Icons.volume_up_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Clear button
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _clearAll,
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // STATES
  // ============================================================================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withOpacity(0.2),
                  const Color(0xFF7B1FA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading symbols...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withOpacity(0.2),
                  const Color(0xFF7B1FA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF9C27B0).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Symbols Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try selecting a different category',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Symbols',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DIALOGS & HELPERS
  // ============================================================================

  void _showModernInfoDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'How to Use AAC',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernInfoStep(
                Icons.category_rounded,
                'Choose Category',
                'Select a category to filter symbols',
                isDark,
              ),
              _buildModernInfoStep(
                Icons.touch_app_rounded,
                'Tap Symbols',
                'Tap symbols to add to your sentence',
                isDark,
              ),
              _buildModernInfoStep(
                Icons.play_arrow_rounded,
                'Speak Sentence',
                'Press play button to hear your sentence',
                isDark,
              ),
              _buildModernInfoStep(
                Icons.close_rounded,
                'Remove Words',
                'Tap X on chips to remove words',
                isDark,
              ),
              _buildModernInfoStep(
                Icons.delete_sweep_rounded,
                'Clear All',
                'Use clear button to remove all symbols',
                isDark,
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoStep(
    IconData icon,
    String title,
    String description,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF9C27B0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showModernSnackBar(String message, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getIconForWord(String word) {
    final iconMap = {
      // Food
      'nasi': Icons.rice_bowl_rounded,
      'roti': Icons.bakery_dining_rounded,
      'ayam': Icons.set_meal_rounded,
      'ikan': Icons.set_meal_rounded,
      'sayur': Icons.eco_rounded,
      'buah': Icons.apple_rounded,
      // Drinks
      'air': Icons.water_drop_rounded,
      'susu': Icons.local_drink_rounded,
      'jus': Icons.coffee_rounded,
      'teh': Icons.coffee_rounded,
      // Emotions
      'senang': Icons.sentiment_very_satisfied_rounded,
      'sedih': Icons.sentiment_dissatisfied_rounded,
      'marah': Icons.sentiment_very_dissatisfied_rounded,
      'takut': Icons.sentiment_neutral_rounded,
      // Activities
      'makan': Icons.restaurant_rounded,
      'minum': Icons.local_drink_rounded,
      'tidur': Icons.bed_rounded,
      'main': Icons.sports_esports_rounded,
      'belajar': Icons.school_rounded,
      // Places
      'rumah': Icons.home_rounded,
      'sekolah': Icons.school_rounded,
      'taman': Icons.park_rounded,
      'mall': Icons.store_rounded,
    };

    return iconMap[word.toLowerCase()] ?? Icons.chat_bubble_rounded;
  }
}