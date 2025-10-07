import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search therapy...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? const Color(0xFF2D2D2D)
              : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF66BB6A),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}