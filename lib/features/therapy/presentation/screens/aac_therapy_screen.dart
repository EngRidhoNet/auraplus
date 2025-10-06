import 'package:aura_plus/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/models/therapy_content.dart';
import '../providers/therapy_provider.dart';

class AACTherapyScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const AACTherapyScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  ConsumerState<AACTherapyScreen> createState() => _AACTherapyScreenState();
}

class _AACTherapyScreenState extends ConsumerState<AACTherapyScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final List<TherapyContent> _selectedSymbols = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    try {
      // Set language ke Bahasa Indonesia
      await _flutterTts.setLanguage("id-ID");
      
      // Set speech rate (kecepatan bicara) - 0.5 = lambat, 1.0 = normal
      await _flutterTts.setSpeechRate(0.4); // 👈 Lebih lambat untuk clarity
      
      // Set volume
      await _flutterTts.setVolume(1.0);
      
      // Set pitch (tinggi rendah suara) - 1.0 = normal
      await _flutterTts.setPitch(1.0);

      // 👇 TAMBAHKAN INI - Set voice secara eksplisit untuk Android
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Untuk Android, cari voice Indonesia
        var voices = await _flutterTts.getVoices;
        
        // Print available voices untuk debugging
        AppLogger.info('Available voices: $voices');
        
        // Cari voice Indonesia
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
      
      // 👇 TAMBAHKAN INI - Set voice untuk iOS
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        await _flutterTts.setVoice({"name": "id-ID-language", "locale": "id-ID"});
      }

      AppLogger.success('TTS initialized with Indonesian voice');
      
    } catch (e) {
      AppLogger.error('Error initializing TTS: $e');
    }
  }


  void _addSymbol(TherapyContent content) {
    setState(() {
      _selectedSymbols.add(content);
    });
  }

  void _removeSymbol(int index) {
    setState(() {
      _selectedSymbols.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedSymbols.clear();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(therapyContentProvider(widget.categoryId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9C27B0), // Purple theme
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Tabs
          _buildCategoryTabs(),

          // AAC Symbol Grid
          Expanded(
            child: contentAsync.when(
              data: (contents) {
                final filteredContents = _selectedCategory == 'all'
                    ? contents
                    : contents
                        .where((c) =>
                            c.title
                                ?.toLowerCase()
                                .contains(_selectedCategory.toLowerCase()) ??
                            false)
                        .toList();

                if (filteredContents.isEmpty) {
                  return _buildEmptyState();
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredContents.length,
                    itemBuilder: (context, index) {
                      return _buildSymbolCard(filteredContents[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF9C27B0),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sentence Builder Bar
          _buildSentenceBuilder(),
        ],
      ),
      floatingActionButton: _selectedSymbols.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Speak Button
                FloatingActionButton(
                  heroTag: 'speak',
                  backgroundColor: const Color(0xFF9C27B0),
                  onPressed: _speak,
                  child: const Icon(Icons.volume_up),
                ),
                const SizedBox(height: 12),
                // Clear Button
                FloatingActionButton(
                  heroTag: 'clear',
                  backgroundColor: Colors.red,
                  mini: true,
                  onPressed: _clearAll,
                  child: const Icon(Icons.clear_all),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'id': 'all', 'name': 'Semua', 'icon': Icons.apps},
      {'id': 'makan', 'name': 'Makanan', 'icon': Icons.restaurant},
      {'id': 'minum', 'name': 'Minuman', 'icon': Icons.local_drink},
      {'id': 'emosi', 'name': 'Emosi', 'icon': Icons.emoji_emotions},
      {'id': 'aktivitas', 'name': 'Aktivitas', 'icon': Icons.directions_run},
      {'id': 'tempat', 'name': 'Tempat', 'icon': Icons.location_on},
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'] as String;
                });
              },
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF9C27B0) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ...existing code...

Widget _buildSymbolCard(TherapyContent content) {
  final displayText = content.title; // Tidak perlu null check karena required
  final imageUrl = content.imageUrl ?? ''; // 👈 Sudah sesuai dengan model baru

  return InkWell(
    onTap: () => _addSymbol(content),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Symbol Image/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE1BEE7), // Light purple
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Color(0xFF9C27B0),
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.chat_bubble_outline,
                    size: 32,
                    color: Color(0xFF9C27B0),
                  ),
          ),
          const SizedBox(height: 8),
          // Symbol Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Update method _speak juga untuk menggunakan targetWord
Future<void> _speak() async {
  if (_selectedSymbols.isEmpty) return;
  
  final sentence = _selectedSymbols
      .map((symbol) => symbol.targetWord) // 👈 Gunakan targetWord
      .join(' ');
  
  await _flutterTts.speak(sentence);
}

// Update sentence builder untuk menampilkan targetWord
Widget _buildSentenceBuilder() {
  return Container(
    height: 120,
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(
                Icons.message,
                color: Color(0xFF9C27B0),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Kalimat Saya:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedSymbols.length} kata',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedSymbols.isEmpty
              ? Center(
                  child: Text(
                    'Pilih symbol untuk membuat kalimat',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _selectedSymbols.length,
                  itemBuilder: (context, index) {
                    final symbol = _selectedSymbols[index];
                    final displayText = symbol.targetWord; // 👈 Gunakan targetWord
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(displayText),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 18,
                        ),
                        onDeleted: () => _removeSymbol(index),
                        backgroundColor: const Color(0xFFE1BEE7),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

// ...existing code...


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada symbol tersedia',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text('Cara Menggunakan AAC'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Pilih kategori yang diinginkan'),
            SizedBox(height: 8),
            Text('2. Tap symbol untuk menambahkan ke kalimat'),
            SizedBox(height: 8),
            Text('3. Tekan tombol speaker untuk membaca kalimat'),
            SizedBox(height: 8),
            Text('4. Tekan X pada chip untuk menghapus kata'),
            SizedBox(height: 8),
            Text('5. Gunakan tombol clear untuk hapus semua'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Mengerti',
              style: TextStyle(color: Color(0xFF9C27B0)),
            ),
          ),
        ],
      ),
    );
  }
}
