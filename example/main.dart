import 'package:pagination_core/pagination_core.dart';

// Example model class
class Post {
  final int id;
  final String title;

  Post({required this.id, required this.title});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(id: json['id'], title: json['title']);
  }
}

Future<Map<String, dynamic>> mockFetchFunction(Map<String, dynamic> query) async {
  await Future.delayed(Duration(seconds: 1));
  int page = int.parse(query['page']);
  return {
    'meta': {'current_page': page, 'last_page': 3},
    'data': List.generate(10, (i) => {'id': i + 1 + (page - 1) * 10, 'title': 'Post Title ${i + 1 + (page - 1) * 10}'}),
  };
}

void main() async {
  final paginator = Paginator<Post>(
    fetchFunction: mockFetchFunction,
    parseItems: (data) => (data as List).map((e) => Post.fromJson(e)).toList(),
    parseMeta: (meta) => Meta.fromJson(meta),
  );

  await paginator.fetch();
  print("Fetched Items: ${paginator.items.length}");

  await paginator.loadNextPage();
  print("After Loading More: ${paginator.items.length}");
}