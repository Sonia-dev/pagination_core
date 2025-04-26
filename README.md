# pagination_core

![pagination](https://github.com/user-attachments/assets/9f49bb83-df0f-4679-abe2-490e23e13436)
<p align="center">
  <a href="https://www.buymeacoffee.com/sonia_flutter" target="_blank">
    <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee" style="width: 250px; height: auto;">
  </a>
</p>

<p align="center">
  ❤️ If you like this project, consider supporting me by buying me a coffee! Every little contribution helps me continue building awesome stuff. Thank you! ☕
</p>

pagination_core is a Flutter/Dart package designed to simplify pagination management in applications. This package makes it easy to load data progressively as the user scrolls through the list, reducing memory load and optimizing performance in apps that handle large amounts of data.
## Installation

Add pagination_core to your pubspec.yaml file:

```yaml
dependencies:
  pagination_core: ^1.0.3

Then, run the following command to install the dependency:

flutter pub get

# pagination_core

🛠️ Basic Usage
Here’s an example usage with mock data :

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

📄 Full Example
A complete example is available in the example folder to guide you through the integration into your project.
💡 Contribution
Contributions are welcome! If you find a bug or want to add a feature, feel free to submit a pull request.
