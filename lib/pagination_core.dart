library pagination_core;

import 'package:flutter/material.dart';

/// Contains pagination metadata such as current page and last page.
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

/// A generic class that handles pagination logic and API data fetching.
class Paginator<T> {
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)
      fetchFunction;
  final List<T> Function(dynamic) parseItems;
  final Meta Function(Map<String, dynamic>) parseMeta;

  final ValueNotifier<List<T>> itemsNotifier = ValueNotifier([]);
  bool isLoading = false;

  /// Default parameters such as page, limit, filters, etc.
  final Map<String, dynamic> parameters;

  int get currentPage =>
      int.tryParse(parameters['page']?.toString() ?? '1') ?? 1;
  int lastPage = 1;

  bool get hasNextPage => currentPage < lastPage;
  bool get showProgress => isLoading && itemsNotifier.value.isNotEmpty;

  Paginator({
    required this.fetchFunction,
    required this.parseItems,
    required this.parseMeta,
    Map<String, dynamic>? initialParameters,
  }) : parameters = initialParameters ?? {'limit': '10', 'page': '1'};

  /// Fetches data from the API with optional reset and extraParams for filtering/searching
  Future<void> fetch({
    bool reset = false,
    Map<String, dynamic>? extraParams,
  }) async {
    if (isLoading) return;
    isLoading = true;

    if (reset) {
      // Only reset the page and the list, keep filters intact
      parameters['page'] = '1';
      lastPage = 1;
      itemsNotifier.value = [];
    }

    // 1) Persist any new filters into parameters
    if (extraParams != null) {
      parameters.addAll(extraParams);
    }

    // 2) Build the final query parameters for the API call
    final queryParams = Map<String, dynamic>.from(parameters);

    try {
      final result = await fetchFunction(queryParams);

      final newItems = parseItems(result['data']);
      final meta = parseMeta(result['meta']);

      // 3) Append new items and update the current page
      itemsNotifier.value = [...itemsNotifier.value, ...newItems];
      parameters['page'] = meta.currentPage.toString();
      lastPage = meta.lastPage;
    } catch (e) {
      debugPrint('Pagination fetch error: $e');
    } finally {
      isLoading = false;
    }
  }

  /// Loads the next page of results
  Future<void> loadNextPage() async {
    if (!hasNextPage || isLoading) return;

    final nextPage = currentPage + 1;
    parameters['page'] = nextPage.toString();
    await fetch();
  }

  /// Manually update a single parameter
  void updateParameter(String key, dynamic value) {
    parameters[key] = value;
  }

  /// Remove a parameter
  void removeParameter(String key) {
    parameters.remove(key);
  }
}

/// A reusable widget that displays a list of paginated items using a Paginator.
class PaginatedList<T> extends StatefulWidget {
  final Paginator<T> paginator;
  final Widget Function(BuildContext, T) itemBuilder;
  final EdgeInsetsGeometry padding;
  final bool skinWrap;
  final Future<void> Function()? onRefresh;
  final Widget? loadingIndicator;
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

    // Initial fetch if the list is empty
    if (widget.paginator.itemsNotifier.value.isEmpty) {
      widget.paginator.fetch();
    }

    // Listen for scroll to trigger loading more
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
        // Build the content inside the RefreshIndicator
        Widget child;
        if (items.isEmpty && widget.paginator.isLoading) {
          // Always show a centered loader during the initial fetch
          child = Center(
              child: widget.loadingIndicator ?? CircularProgressIndicator());
        } else if (items.isEmpty) {
          // If empty and not loading, show the emptyBuilder centered
          child = widget.emptyBuilder ??
              const Center(child: Text("No items found."));
        } else {
          // Normal list with bottom loader if more pages exist
          child = ListView.builder(
            controller: _scrollController,
            padding: widget.padding,
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
                return widget.paginator.hasNextPage
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: widget.loadingIndicator ??
                            const CircularProgressIndicator(),
                      )
                    : const SizedBox.shrink();
              }
              return widget.itemBuilder(context, items[index]);
            },
          );
        }

        // Wrap everything in a RefreshIndicator with always-scrollable behavior
        return RefreshIndicator(
          onRefresh: () async {
            await widget.paginator.fetch(reset: true);
            if (widget.onRefresh != null) await widget.onRefresh!();
          },
          child: items.isEmpty
              // Force a scrollable ListView when empty to enable pull-to-refresh
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: child,
                    )
                  ],
                )
              : child,
        );
      },
    );
  }
}
