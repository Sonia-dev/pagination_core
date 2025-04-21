library pagination_core;

/// Contains pagination metadata such as current page and last page.
class Meta {
  /// The current page number.
  final int currentPage;

  /// The last page number available.
  final int lastPage;

  /// Creates a [Meta] object with the given [currentPage] and [lastPage].
  Meta({required this.currentPage, required this.lastPage});

  /// Creates a [Meta] object from a JSON map.
  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currentPage: json['currentPage'] ?? 1,
      lastPage: json['lastPage'] ?? 1,
    );
  }
}

/// A reusable pagination controller to fetch and manage paged data.
class Paginator<T> {
  /// The function used to fetch paginated data from an API.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)
      fetchFunction;

  /// Function to parse list of items from the response data.
  final List<T> Function(dynamic) parseItems;

  /// Function to parse [Meta] data from the response.
  final Meta Function(Map<String, dynamic>) parseMeta;

  /// List of currently loaded items.
  List<T> items = [];

  /// Current page index being viewed or fetched.
  int currentPage = 1;

  /// The last available page number.
  int lastPage = 1;

  /// Indicates whether data is being fetched.
  bool isLoading = false;

  /// Indicates whether there is another page to load.
  bool get hasNextPage => currentPage < lastPage;

  /// Shows a progress indicator while loading additional pages.
  bool get showProgress => isLoading && items.isNotEmpty;

  /// Creates a [Paginator] with the necessary fetch and parsing functions.
  Paginator({
    required this.fetchFunction,
    required this.parseItems,
    required this.parseMeta,
  });

  /// Fetches the data for the current page.
  /// If [reset] is true, resets the pagination and fetches the first page.
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

  /// Loads the next page if available.
  Future<void> loadNextPage() async {
    if (!hasNextPage || isLoading) return;

    currentPage++;
    await fetch();
  }
}
