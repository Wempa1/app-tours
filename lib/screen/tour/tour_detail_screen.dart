import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TourDetailScreen extends StatefulWidget {
  final String tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  final _sb = Supabase.instance.client;
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final tour = await _sb.from('tours').select().eq('id', widget.tourId).maybeSingle();
    final stopsRaw = await _sb.from('stops').select().eq('tour_id', widget.tourId).order('order_index', ascending: true);
    final stops = List<Map<String, dynamic>>.from(stopsRaw as List? ?? const []);
    return {'tour': (tour ?? <String, dynamic>{}), 'stops': stops};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(appBar: AppBar(), body: Center(child: Text('Error: ${snap.error}')));
        }

        final data = Map<String, dynamic>.from((snap.data as Map?) ?? const {});
        final tour = Map<String, dynamic>.from((data['tour'] as Map?) ?? const {});
        final stops = List<Map<String, dynamic>>.from((data['stops'] as List?) ?? const []);

        return Scaffold(
          appBar: AppBar(title: Text((tour['title'] ?? 'Tour') as String)),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (c, i) {
              final s = stops[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${s['order_index']}')),
                title: Text((s['title'] ?? '') as String),
                subtitle: Text(((s['description'] ?? '') as String)),
              );
            },
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemCount: stops.length,
          ),
        );
      },
    );
  }
}
