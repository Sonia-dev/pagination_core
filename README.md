# pagination_core

pagination_core is a Flutter/Dart package designed to simplify pagination management in applications. This package makes it easy to load data progressively as the user scrolls through the list, reducing memory load and optimizing performance in apps that handle large amounts of data.
## Installation

Add pagination_core to your pubspec.yaml file:

```yaml
dependencies:
  pagination_core: ^1.0.2

Then, run the following command to install the dependency:

flutter pub get

🛠️ Basic Usage

Here’s an example usage with mock data :
final paginator = Paginator<String>(
      fetchFunction: mockApiFetch,
      parseItems: (data) => List<String>.from(data),
      parseMeta: (json) => Meta.fromJson(json),
    );

Then, use paginator.fetch() to load the initial data and paginator.loadNextPage() to load the next page. 
📄 Full Example
A complete example is available in the example folder to guide you through the integration into your project.
💡 Contribution
Contributions are welcome! If you find a bug or want to add a feature, feel free to submit a pull request.

![pagination_example.png](assets%2Fpagination_example.png)