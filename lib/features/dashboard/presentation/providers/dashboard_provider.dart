import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Current tab index (0: Home, 1: Therapy, 2: Resources, 3: Profile)
final dashboardTabProvider = StateProvider<int>((ref) => 0);

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filter results based on search
final filteredTherapiesProvider = Provider<List<TherapyItem>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final allTherapies = _allTherapies;
  
  if (query.isEmpty) return allTherapies;
  
  return allTherapies.where((therapy) {
    return therapy.title.toLowerCase().contains(query) ||
           therapy.description.toLowerCase().contains(query);
  }).toList();
});

// Therapy items data
class TherapyItem {
  final String title;
  final String description;
  final String icon;
  final String color;
  final String route;

  TherapyItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}

// Sample therapy data
final _allTherapies = [
  TherapyItem(
    title: 'Vocabulary Therapy',
    description: 'Learn new words with AR',
    icon: 'school',
    color: '#66BB6A',
    route: '/vocabulary',
  ),
  TherapyItem(
    title: 'Verbal Therapy',
    description: 'Practice pronunciation',
    icon: 'record_voice_over',
    color: '#FF9800',
    route: '/verbal',
  ),
  TherapyItem(
    title: 'AAC Communication',
    description: 'Symbol-based communication',
    icon: 'touch_app',
    color: '#9C27B0',
    route: '/aac',
  ),
  TherapyItem(
    title: 'Speech Practice',
    description: 'Improve speaking skills',
    icon: 'mic',
    color: '#E91E63',
    route: '/speech',
  ),
];