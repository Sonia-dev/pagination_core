import 'package:flutter/material.dart';
import 'package:pagination_core/pagination_core.dart';

/// Simulates a paginated screen with Gmail-like styling.
class PaginatedListScreen extends StatefulWidget {
  @override
  _PaginatedListScreenState createState() => _PaginatedListScreenState();
}

class _PaginatedListScreenState extends State<PaginatedListScreen> {
  late Paginator<String> paginator;

  @override
  void initState() {
    super.initState();

    // Initialize the paginator with fetch logic and response parsing.
    paginator = Paginator<String>(
      fetchFunction: mockApiFetch,
      parseItems: (data) => List<String>.from(data),
      parseMeta: (json) => Meta.fromJson(json),
    );

    // Fetch the first page on screen load.
    paginator.fetch();
  }

  /// Simulates an API call returning paginated string data.
  Future<Map<String, dynamic>> mockApiFetch(Map<String, dynamic> params) async {
    final page = int.parse(params['page'] ?? '1');
    await Future.delayed(Duration(seconds: 1));

    return {
      'data': List.generate(10, (i) => 'Item ${(page - 1) * 10 + i + 1}'),
      'meta': {'currentPage': page, 'lastPage': 5},
    };
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
                        "This is a sample message preview .",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black54),
                      ),
                      trailing:
                          const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
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
                        );
                      },
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
