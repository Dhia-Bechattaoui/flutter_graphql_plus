import 'package:flutter/material.dart';
import 'package:flutter_graphql_plus/flutter_graphql_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter GraphQL Plus Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GraphQLExamplePage(),
    );
  }
}

class GraphQLExamplePage extends StatefulWidget {
  const GraphQLExamplePage({super.key});

  @override
  State<GraphQLExamplePage> createState() => _GraphQLExamplePageState();
}

class _GraphQLExamplePageState extends State<GraphQLExamplePage> {
  late GraphQLClient client;
  String? queryResult;
  String? errorMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    client = GraphQLClient(
      endpoint: 'https://api.example.com/graphql',
      defaultHeaders: {
        'Content-Type': 'application/json',
      },
    );

    try {
      await client.initialize();
      // GraphQL client initialized successfully
    } catch (e) {
      // Failed to initialize GraphQL client: $e
    }
  }

  Future<void> _executeQuery() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      const request = GraphQLRequest(
        query: '''
          query GetUser(\$id: ID!) {
            user(id: \$id) {
              id
              name
              email
            }
          }
        ''',
        variables: {'id': '123'},
        cachePolicy: CachePolicy.cacheFirst,
      );

      final response = await client.query(request);

      if (response.isSuccessful) {
        setState(() {
          queryResult = response.data.toString();
        });
      } else {
        setState(() {
          errorMessage = response.errors?.first.message ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _executeMutation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      const request = GraphQLRequest(
        query: '''
          mutation CreateUser(\$input: CreateUserInput!) {
            createUser(input: \$input) {
              id
              name
              email
            }
          }
        ''',
        variables: {
          'input': {
            'name': 'John Doe',
            'email': 'john@example.com',
          },
        },
        persistOffline: true,
      );

      final response = await client.mutate(request);

      if (response.isSuccessful) {
        setState(() {
          queryResult = 'User created: ${response.data.toString()}';
        });
      } else {
        setState(() {
          errorMessage = response.errors?.first.message ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSubscriptionExample() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Example'),
        content: const Text(
          'This would demonstrate real-time subscriptions. '
          'In a real app, you would see live updates from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter GraphQL Plus Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GraphQL Client Demo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Endpoint: ${client.endpoint}'),
                    Text('Connected: ${client.isConnected}'),
                    Text('Cache Stats: ${client.getCacheStats()}'),
                    Text('Offline Stats: ${client.getOfflineStats()}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _executeQuery,
                    child: const Text('Execute Query'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _executeMutation,
                    child: const Text('Execute Mutation'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showSubscriptionExample,
              child: const Text('Show Subscription Example'),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (queryResult != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Query Result:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(queryResult!),
                    ],
                  ),
                ),
              ),
            if (errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.dispose();
    super.dispose();
  }
}
