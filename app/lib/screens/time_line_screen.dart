import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../widgets/memory_timeline_item.dart';

class TimeLineScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<TimeLineScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MemoryProvider>().fetchMemories());
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = context.watch<MemoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Our Little World',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: memoryProvider.memories.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: memoryProvider.memories.length,
              itemBuilder: (context, index) {
                return MemoryTimelineItem(
                  memory: memoryProvider.memories[index],
                );
              },
            ),
    );
  }
}
