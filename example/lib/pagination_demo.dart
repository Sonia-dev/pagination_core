import 'package:flutter/material.dart';
import 'package:pagination_core/pagination_core.dart';

class PaginatedListScreen extends StatefulWidget {
  @override
  _PaginatedListScreenState createState() => _PaginatedListScreenState();
}

class _PaginatedListScreenState extends State<PaginatedListScreen> {
  late Paginator<String> paginator;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Example categories for the filter chips
  final List<String> categories = ['inbox', 'sent', 'draft'];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();

    // Initialize the paginator
    paginator = Paginator<String>(
      fetchFunction: mockApiFetch,
      parseItems: (data) => List<String>.from(data),
      parseMeta: (json) => Meta.fromJson(json),
      initialParameters: {
        'limit': '10',
        'page': '1',
        // Pre-apply a category filter if set
        if (selectedCategory != null) 'category': selectedCategory,
      },
    );

    // Fetch the first page
    paginator.fetch();
  }

  /// Simulates a paginated API call with search and category filtering
  Future<Map<String, dynamic>> mockApiFetch(Map<String, dynamic> params) async {
    final page = int.parse(params['page'] ?? '1');
    final query = (params['query'] ?? '').toString().toLowerCase();
    final category = params['category']?.toString().toLowerCase();

    await Future.delayed(const Duration(seconds: 1));

    // Full data set
    final allItems = List.generate(50, (i) => 'Item ${i + 1}');

    // Apply filters
    List<String> filtered = allItems.where((item) {
      final matchesSearch = query.isEmpty || item.toLowerCase().contains(query);
      final matchesCategory =
          category == null || item.toLowerCase().contains(category);
      return matchesSearch && matchesCategory;
    }).toList();

    // Pagination logic
    final limit = int.parse(params['limit'] ?? '10');
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, filtered.length);
    final pagedItems = filtered.sublist(start, end);

    final lastPage = (filtered.length / limit).ceil();

    return {
      'data': pagedItems,
      'meta': {
        'currentPage': page,
        'lastPage': lastPage,
      },
    };
  }

  /// Called when the search input changes
  void _onSearchChanged(String value) {
    searchQuery = value;
    paginator.fetch(reset: true, extraParams: {'query': searchQuery});
  }

  /// Called when a category chip is selected
  void _onCategorySelected(String? category) {
    setState(() {
      selectedCategory = category;
    });
    final extra = <String, dynamic>{};
    if (category != null) extra['category'] = category;
    paginator.fetch(reset: true, extraParams: {'category': selectedCategory});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Inbox"),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search emails...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Category filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: selectedCategory == null,
                  onSelected: (_) => _onCategorySelected(null),
                ),
                ...categories.map((cat) => FilterChip(
                      label: Text(cat.capitalize()),
                      selected: selectedCategory == cat,
                      onSelected: (_) => _onCategorySelected(cat),
                    )),
              ],
            ),
          ),

          // Paginated list
          Expanded(
            child: PaginatedList<String>(
              paginator: paginator,
              itemBuilder: (context, item) {
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.email, color: Colors.white),
                      ),
                      title: Text(
                        item,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      subtitle: const Text(
                        "This is a sample message preview.",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black54),
                      ),
                      trailing:
                          const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(item),
                          content: const Text(
                              "This would be the full content of the email/message."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
              padding: const EdgeInsets.only(top: 8),
              emptyBuilder: const Center(child: Text("Your inbox is empty")),
              loadingIndicator:
                  const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension method to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
