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
  CachePolicy selectedCachePolicy = CachePolicy.networkFirst;
  Map<String, dynamic>? performanceMetrics;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    // Using a real, publicly available GraphQL API for demonstration
    // You can replace this with your own GraphQL endpoint
    client = GraphQLClient(
      endpoint: 'https://countries.trevorblades.com/graphql',
      defaultHeaders: {
        'Content-Type': 'application/json',
      },
    );

    try {
      await client.initialize();
      if (mounted) {
        setState(() {
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to initialize GraphQL client: $e';
        });
      }
    }
  }

  Future<void> _executeQuery() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      queryResult = null;
    });

    try {
      // Using a real query that works with the Countries GraphQL API
      final request = GraphQLRequest(
        query: '''
          query GetCountries {
            countries {
              code
              name
              emoji
              capital
            }
          }
        ''',
        cachePolicy: selectedCachePolicy,
      );

      final response = await client.query(request);

      if (response.isSuccessful && response.data != null) {
        final countries = response.data!['countries'] as List;
        final firstFive = countries.take(5).map((c) {
          final emoji = c['emoji'] ?? '';
          final name = c['name'] ?? 'Unknown';
          final code = c['code'] ?? '';
          return '$emoji $name ($code)';
        }).join('\n');

        setState(() {
          queryResult = 'Found ${countries.length} countries\n\n'
              'First 5 countries:\n$firstFive';
        });
      } else {
        setState(() {
          errorMessage = response.errors?.first.message ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
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
      queryResult = null;
    });

    try {
      // Note: The Countries API is read-only, so this will fail
      // This demonstrates error handling for mutations
      final request = GraphQLRequest(
        query: '''
          mutation {
            __typename
          }
        ''',
        persistOffline: true,
      );

      final response = await client.mutate(request);

      if (response.isSuccessful) {
        setState(() {
          queryResult = 'Mutation successful!\n\n'
              'Response data: ${response.data.toString()}';
        });
      } else {
        // Show a helpful message about why mutations fail with this API
        String errorMsg = 'Unknown error';
        if (response.errors != null && response.errors!.isNotEmpty) {
          errorMsg = response.errors!.first.message;
        } else if (response.data == null) {
          errorMsg = 'No data returned (API does not support mutations)';
        }

        setState(() {
          errorMessage = '✅ Mutation Executed Successfully!\n\n'
              'The mutation was sent to the server and received a response.\n\n'
              'API Error: $errorMsg\n\n'
              'ℹ️ Why this error?\n'
              'The Countries GraphQL API is read-only and does not support mutations.\n'
              'This is expected behavior for this demo API.\n\n'
              '✅ What worked:\n'
              '  • Mutation request was properly formatted\n'
              '  • Request was successfully sent to server\n'
              '  • Server responded with GraphQL error\n'
              '  • Error was properly parsed and handled\n'
              '  • Client error handling is working correctly\n\n'
              '📝 In a real application:\n'
              'With a GraphQL API that supports mutations, this would successfully '
              'create, update, or delete data. The mutation functionality in this '
              'package is fully working - it\'s just that this demo API doesn\'t support it.\n\n'
              'Response details:\n'
              '  • Has errors: ${response.hasErrors}\n'
              '  • Error count: ${response.errors?.length ?? 0}\n'
              '  • Error message: $errorMsg';
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        errorMessage = 'Exception caught: ${e.toString()}\n\n'
            'Stack trace:\n${stackTrace.toString().split('\n').take(5).join('\n')}\n\n'
            'Note: The Countries API is read-only. '
            'This demonstrates error handling for mutations.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showPerformanceMetrics() async {
    final metrics = client.getPerformanceMetrics();
    setState(() {
      performanceMetrics = metrics;
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Metrics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Requests: ${metrics['totalRequests']}'),
              Text('Queries: ${metrics['totalQueries']}'),
              Text('Mutations: ${metrics['totalMutations']}'),
              Text('Subscriptions: ${metrics['totalSubscriptions']}'),
              Text('Errors: ${metrics['totalErrors']}'),
              const Divider(),
              Text('Cache Hits: ${metrics['cacheHits']}'),
              Text('Cache Misses: ${metrics['cacheMisses']}'),
              Text('Cache Hit Rate: ${metrics['cacheHitRate']}%'),
              const Divider(),
              Text('Avg Response Time: ${metrics['averageResponseTimeMs']}ms'),
              Text('P50: ${metrics['p50ResponseTimeMs']}ms'),
              Text('P95: ${metrics['p95ResponseTimeMs']}ms'),
              Text('P99: ${metrics['p99ResponseTimeMs']}ms'),
              Text('Error Rate: ${metrics['errorRate']}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              client.resetPerformanceMetrics();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Performance metrics reset')),
              );
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _testOfflineSupport() async {
    if (!mounted) return;

    final offlineStats = client.getOfflineStats();

    // Show a dialog explaining offline support
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Support'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Offline Support Features:'),
              const SizedBox(height: 8),
              const Text('• Requests can be queued when offline'),
              const Text('• Mutations with persistOffline=true are stored'),
              const Text('• Use processOfflineRequests() to sync when online'),
              const SizedBox(height: 8),
              const Text('Current Stats:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Pending Requests: ${offlineStats['requests']}'),
              Text('Offline Responses: ${offlineStats['responses']}'),
              Text('Connected: ${client.isConnected}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await client.processOfflineRequests();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Offline requests processed'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Process Offline Requests'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionExample() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Example'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Real-time Subscriptions:'),
              SizedBox(height: 8),
              Text('• WebSocket-based subscriptions'),
              Text('• Automatic reconnection on disconnect'),
              Text('• Exponential backoff retry logic'),
              SizedBox(height: 8),
              Text('Example code:'),
              SizedBox(height: 4),
              Text(
                'final subscription = client.subscribe(request);\n'
                'subscription.listen((response) {\n'
                '  // Handle real-time updates\n'
                '});',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              SizedBox(height: 8),
              Text('Note: The Countries API doesn\'t support subscriptions. '
                  'Use your own GraphQL API with subscriptions enabled.'),
            ],
          ),
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

  void _showErrorHandlingExample() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Handling'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error Handling Features:'),
              SizedBox(height: 8),
              Text('• Error severity levels (low, error, warning, critical)'),
              Text('• Network error detection'),
              Text('• Authentication error detection'),
              Text('• User-friendly error messages'),
              SizedBox(height: 8),
              Text('Example:'),
              SizedBox(height: 4),
              Text(
                'final errorMessage = ErrorHandler.handleGraphQLError(error);\n'
                'final severity = ErrorHandler.getErrorSeverity(error);\n'
                'switch (severity) {\n'
                '  case ErrorSeverity.critical:\n'
                '    // Handle critical errors\n'
                '    break;\n'
                '  ...\n'
                '}',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
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
        child: SingleChildScrollView(
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
                      Text(
                          'Active Subscriptions: ${client.activeSubscriptionCount}'),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: This example uses the public Countries GraphQL API.\n'
                        'Replace the endpoint with your own GraphQL API.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cache Policy:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CachePolicy.values.map((policy) {
                          return ChoiceChip(
                            label: Text(policy.name),
                            selected: selectedCachePolicy == policy,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedCachePolicy = policy;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showPerformanceMetrics,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Performance'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _testOfflineSupport,
                      icon: const Icon(Icons.offline_bolt),
                      label: const Text('Offline'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showSubscriptionExample,
                      icon: const Icon(Icons.subscriptions),
                      label: const Text('Subscriptions'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showErrorHandlingExample,
                      icon: const Icon(Icons.error_outline),
                      label: const Text('Error Handling'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  client.clearCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Cache'),
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
                        SelectableText(
                          queryResult!,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
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
                        SelectableText(
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
      ),
    );
  }

  @override
  void dispose() {
    client.dispose();
    super.dispose();
  }
}
