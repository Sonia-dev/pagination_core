import 'package:example/post_model.dart';
import 'package:flutter/material.dart';
import 'package:pagination_core/pagination_core.dart';

class PaginatedDemo extends StatefulWidget {
  const PaginatedDemo({Key? key}) : super(key: key);

  @override
  State<PaginatedDemo> createState() => _PaginatedDemoState();
}

class _PaginatedDemoState extends State<PaginatedDemo> {
  final ScrollController _scrollController = ScrollController();
  late final Paginator<Post> paginator;

  @override
  void initState() {
    super.initState();
    paginator = Paginator<Post>(
      fetchFunction: _mockFetchPosts,
      parseItems: (data) =>
          (data as List).map((e) => Post.fromJson(e)).toList(),
      parseMeta: (meta) => Meta.fromJson(meta),
    );

    _loadInitialData();
    _scrollController.addListener(() async {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !paginator.isLoading &&
          paginator.hasNextPage) {
        setState(() {});
        await paginator.loadNextPage();
        setState(() {});
      }
    });
  }

  Future<void> _loadInitialData() async {
    await paginator.fetch();
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paginator Scroll Pagination")),
      body: (paginator.isLoading && !paginator.showProgress)
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount:
                  paginator.items.length + (paginator.showProgress ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == paginator.items.length && paginator.showProgress) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final post = paginator.items[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.email, color: Colors.blue),
                    title: Text(post.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      post.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(post.title),
                          content: Text(post.body),
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
                );
              },
            ),
    );
  }

  /// Simulated fetch function with fake data
  Future<Map<String, dynamic>> _mockFetchPosts(
      Map<String, dynamic> params) async {
    await Future.delayed(const Duration(seconds: 1));

    final int page = int.parse(params['page'] ?? '1');
    final int limit = int.parse(params['limit'] ?? '10');

    final int start = (page - 1) * limit;
    final int end = (start + limit).clamp(0, 50);

    final List<Map<String, dynamic>> data = List.generate(
      end - start,
      (index) => {
        'id': start + index + 1,
        'title': 'Post ${start + index + 1}',
        'body': 'This is the body content of post ${start + index + 1}.',
      },
    );

    return {
      'data': data,
      'meta': {
        'currentPage': page,
        'lastPage': (50 / limit).ceil(),
      }
    };
  }
}
