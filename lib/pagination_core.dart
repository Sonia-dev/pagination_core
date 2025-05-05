library pagination_core;

import 'package:flutter/material.dart';

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

/// A generic class that handles pagination logic and API data fetching.
class Paginator<T> {
  /// Function used to fetch data from the API, accepts query parameters.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)
      fetchFunction;

  /// Function that parses the response into a list of type T.
  final List<T> Function(dynamic) parseItems;

  /// Function that parses pagination metadata (current page, last page).
  final Meta Function(Map<String, dynamic>) parseMeta;

  /// A notifier that holds the current list of fetched items.
  final ValueNotifier<List<T>> itemsNotifier = ValueNotifier([]);

  /// Tracks the current page being fetched.
  int currentPage = 1;

  /// Tracks the last page number available.
  int lastPage = 1;

  /// Indicates whether a fetch operation is in progress.
  bool isLoading = false;

  /// Returns true if there are more pages to load.
  bool get hasNextPage => currentPage < lastPage;

  /// Returns true if loading and already has some items loaded.
  bool get showProgress => isLoading && itemsNotifier.value.isNotEmpty;

  /// Constructor requiring the necessary fetch and parsing functions.
  Paginator({
    required this.fetchFunction,
    required this.parseItems,
    required this.parseMeta,
  });

  /// Fetches data for the current page.
  /// If [reset] is true, it resets pagination and fetches the first page again.
  Future<void> fetch({bool reset = false}) async {
    if (isLoading) return;

    isLoading = true;

    if (reset) {
      // Reset pagination state
      currentPage = 1;
      lastPage = 1;
      itemsNotifier.value = [];
    }

    try {
      // Call API with page and limit parameters
      final result = await fetchFunction({
        'page': currentPage.toString(),
        'limit': '10',
      });

      // Parse the items and meta data from the response
      final newItems = parseItems(result['data']);
      final meta = parseMeta(result['meta']);

      // Add new items to the existing list
      itemsNotifier.value = [...itemsNotifier.value, ...newItems];
      currentPage = meta.currentPage;
      lastPage = meta.lastPage;
    } finally {
      isLoading = false;
    }
  }

  /// Loads the next page if available.
  Future<void> loadNextPage() async {
    if (!hasNextPage || isLoading) return;
    currentPage++;
    await fetch();
  }
}

/// A reusable widget to display a list of paginated items using a Paginator.
class PaginatedList<T> extends StatefulWidget {
  /// The paginator that handles the fetching logic.
  final Paginator<T> paginator;

  /// Builder function to create UI for each item.
  final Widget Function(BuildContext, T) itemBuilder;

  /// Padding around the list.
  final EdgeInsetsGeometry padding;
  final bool skinWrap;

  /// Optional callback triggered when the list is refreshed.
  final Future<void> Function()? onRefresh;

  /// Optional custom loading widget.
  final Widget? loadingIndicator;

  /// Optional widget to show when the list is empty.
  final Widget? emptyBuilder;

  const PaginatedList({
    Key? key,
    required this.paginator,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(8),
    this.skinWrap = true,
    this.onRefresh,
    this.loadingIndicator,
    this.emptyBuilder,
  }) : super(key: key);

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Fetch data initially if the list is empty
    if (widget.paginator.itemsNotifier.value.isEmpty) {
      widget.paginator.fetch();
    }

    // Listen for scroll events to trigger loading more pages
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          widget.paginator.hasNextPage &&
          !widget.paginator.isLoading) {
        widget.paginator.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<T>>(
      valueListenable: widget.paginator.itemsNotifier,
      builder: (context, items, _) {
        // Show loading when data is being fetched and list is still empty
        if (items.isEmpty && widget.paginator.isLoading) {
          return Center(
            child: widget.loadingIndicator ?? CircularProgressIndicator(),
          );
        }

        // Show empty message when list has no items
        if (items.isEmpty) {
          return widget.emptyBuilder ??
              const Center(child: Text("No items found."));
        }

        // Main scrollable list with refresh support
        return RefreshIndicator(
          onRefresh: () async {
            await widget.paginator.fetch(reset: true);
            if (widget.onRefresh != null) await widget.onRefresh!();
          },
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: widget.skinWrap,
            padding: widget.padding,
            itemCount: items.length + 1, // Extra item for progress indicator
            itemBuilder: (context, index) {
              if (index == items.length) {
                // Display loader at the end if more pages are available
                return widget.paginator.hasNextPage
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: widget.loadingIndicator ??
                            const Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink(); // Empty space if no more pages
              }

              return widget.itemBuilder(context, items[index]);
            },
          ),
        );
      },
    );
  }
}
