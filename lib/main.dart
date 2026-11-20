import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/queue_provider.dart';
import 'package:waiting_room_app/supabase_config.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/geolocation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (error) {
      debugPrint('Anonymous sign-in unavailable: $error');
    }
  }
  runApp(WaitingRoomApp(useSupabase: SupabaseConfig.isConfigured));
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({
    super.key,
    this.useSupabase = false,
    this.localQueueService,
    this.geoService,
  });

  final bool useSupabase;
  final LocalQueueService? localQueueService;
  final GeolocationService? geoService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QueueProvider(
        useSupabase: useSupabase,
        localService: localQueueService,
        geoService: geoService,
      )..initialize(),
      child: const MaterialApp(home: WaitingRoomScreen()),
    );
  }
}

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  Future<void> _addClient() async {
    final clientName = _controller.text.trim();
    if (clientName.isEmpty) return;
    try {
      await context.read<QueueProvider>().addClient(clientName);
      _controller.clear();
      if (mounted) setState(() => _errorMessage = null);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to add client: $error');
      }
    }
  }

  Future<void> _removeClient(int index) async {
    try {
      await context.read<QueueProvider>().removeClientAt(index);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to remove client: $error');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Local Waiting Room')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'Client Name'),
                    onSubmitted: (_) => _addClient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addClient, child: const Text('Add')),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            Text('Clients in Queue: ${queue.clients.length}'),
            TextButton(
              onPressed: queue.clients.isEmpty
                  ? null
                  : () => context.read<QueueProvider>().nextClient(),
              child: const Text('Next Client'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: queue.clients.length,
                itemBuilder: (context, index) => Card(
                  child: ListTile(
                    title: Text(queue.clients[index].name),
                    subtitle: Text(
                      queue.clients[index].latitude == null
                          ? '📍 Location not captured'
                          : '📍 ${queue.clients[index].latitude!.toStringAsFixed(4)}, '
                                '${queue.clients[index].longitude!.toStringAsFixed(4)}',
                    ),
                    trailing: ElevatedButton(
                      key: ValueKey('remove-client-$index'),
                      onPressed: () => _removeClient(index),
                      child: const Text('Remove'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
