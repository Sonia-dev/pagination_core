library pagination_core;

class Meta {
  final int currentPage;
  final int lastPage;

  Meta({required this.currentPage, required this.lastPage});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currentPage: json['currentPage'] ?? 1,
      lastPage: json['lastPage'] ?? 1,
    );
  }
}

class Paginator<T> {
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)
      fetchFunction;
  final List<T> Function(dynamic) parseItems;
  final Meta Function(Map<String, dynamic>) parseMeta;

  List<T> items = [];
  int currentPage = 1;
  int lastPage = 1;
  bool isLoading = false;

  bool get hasNextPage => currentPage < lastPage;
  bool get showProgress => isLoading && items.isNotEmpty;

  Paginator({
    required this.fetchFunction,
    required this.parseItems,
    required this.parseMeta,
  });

  Future<void> fetch({bool reset = false}) async {
    if (isLoading) return;

    isLoading = true;

    if (reset) {
      currentPage = 1;
      items.clear();
    }

    final result =
        await fetchFunction({'page': currentPage.toString(), 'limit': '10'});

    final List<T> newItems = parseItems(result['data']);
    final Meta meta = parseMeta(result['meta']);

    items.addAll(newItems);
    currentPage = meta.currentPage;
    lastPage = meta.lastPage;

    isLoading = false;
  }

  Future<void> loadNextPage() async {
    if (!hasNextPage || isLoading) return;

    currentPage++;
    await fetch();
  }
}
