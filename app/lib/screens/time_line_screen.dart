import 'package:app/models/memory_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/memory_timeline_item.dart';
import '../utils/database_helper.dart';
import 'add_memory_screen.dart';
import 'profile_screen.dart';

class TimeLineScreen extends StatefulWidget {
  @override
  _TimeLineScreenState createState() => _TimeLineScreenState();
}

class _TimeLineScreenState extends State<TimeLineScreen>
    with TickerProviderStateMixin {
  String? _userRole;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    _loadUserRole();
    Future.microtask(() => context.read<MemoryProvider>().fetchMemories());
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _loadUserRole() async {
    try {
      final role = await DatabaseHelper().getCharacterChoice();
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  void _toggleFilterMenu() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });

    if (_isFilterExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = context.watch<MemoryProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _userRole == 'Panda'
                ? Image.asset(
                    'assets/images/panda_avatar.png',
                    width: 32,
                    height: 32,
                  )
                : Image.asset(
                    'assets/images/penguin_avatar.png',
                    width: 32,
                    height: 32,
                  ),
            const SizedBox(width: 8),
            Text(
              'Our Little World',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _userRole == 'Panda' ? '🐧' : '🐼',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_alt),
                if (memoryProvider.currentFilter != MemoryFilterType.newest ||
                    memoryProvider.authorFilter != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => memoryProvider.fetchMemories(),
        child: memoryProvider.isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your memories...'),
                  ],
                ),
              )
            : memoryProvider.errorMessage != null
            ? _buildErrorState(memoryProvider.errorMessage!)
            : memoryProvider.memories.isEmpty
            ? _buildEmptyState()
            : _buildTimeline(memoryProvider.memories),
      ),
      floatingActionButton: _buildFloatingActionButton(authProvider),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.read<MemoryProvider>().fetchMemories(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              _userRole == 'Panda' ? '🐼💕🐧' : '🐧💕🐼',
              style: const TextStyle(fontSize: 60),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'No Memories Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Start creating beautiful memories together!\nCapture moments, add places, and build your story.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddMemory(),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Create First Memory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<Memory> memories) {
    return Column(
      children: [
        // Filter summary bar
        if (context.watch<MemoryProvider>().currentFilter !=
                MemoryFilterType.newest ||
            context.watch<MemoryProvider>().authorFilter != null)
          _buildFilterSummary(),

        // Timeline list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 100, // Extra padding to avoid FAB overlap
            ),
            itemCount: memories.length,
            itemBuilder: (context, index) {
              final memory = memories[index];
              return MemoryTimelineItem(
                memory: memory,
                isFirst: index == 0,
                isLast: index == memories.length - 1,
                userRole: _userRole,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSummary() {
    final memoryProvider = context.watch<MemoryProvider>();
    String filterText = '';

    switch (memoryProvider.currentFilter) {
      case MemoryFilterType.newest:
        filterText = 'Newest First';
        break;
      case MemoryFilterType.oldest:
        filterText = 'Oldest First';
        break;
      case MemoryFilterType.thisMonth:
        filterText = 'This Month';
        break;
      case MemoryFilterType.lastMonth:
        filterText = 'Last Month';
        break;
      case MemoryFilterType.thisYear:
        filterText = 'This Year';
        break;
      case MemoryFilterType.byAuthor:
        filterText = 'By ${memoryProvider.authorFilter}';
        break;
    }

    if (memoryProvider.authorFilter != null &&
        memoryProvider.currentFilter != MemoryFilterType.byAuthor) {
      filterText += ' • ${memoryProvider.authorFilter}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt,
            size: 16,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            filterText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => memoryProvider.clearFilters(),
            child: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), // Push FAB above nav bar
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Filter FAB (when expanded)
          AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimation.value,
                child: _fabAnimation.value > 0
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: FloatingActionButton(
                          heroTag: 'filter_fab',
                          mini: true,
                          onPressed: _showFilterOptions,
                          backgroundColor: Theme.of(context).cardColor,
                          elevation: 4,
                          child: Icon(
                            Icons.filter_alt,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),

          // Main FAB
          FloatingActionButton(
            heroTag: 'main_fab',
            onPressed: () => _navigateToAddMemory(),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            elevation: 8,
            child: Icon(
              _isFilterExpanded ? Icons.close : Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    final memoryProvider = context.read<MemoryProvider>();
    final uniqueAuthors = memoryProvider.uniqueAuthors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Filter Memories',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Time-based filters
              Text(
                'Sort by Time',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    'Newest First',
                    MemoryFilterType.newest,
                    Icons.trending_down,
                  ),
                  _buildFilterChip(
                    'Oldest First',
                    MemoryFilterType.oldest,
                    Icons.trending_up,
                  ),
                  _buildFilterChip(
                    'This Month',
                    MemoryFilterType.thisMonth,
                    Icons.calendar_today,
                  ),
                  _buildFilterChip(
                    'Last Month',
                    MemoryFilterType.lastMonth,
                    Icons.calendar_view_month,
                  ),
                  _buildFilterChip(
                    'This Year',
                    MemoryFilterType.thisYear,
                    Icons.date_range,
                  ),
                ],
              ),

              if (uniqueAuthors.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Filter by Author',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: uniqueAuthors.map((author) {
                    final isSelected = memoryProvider.authorFilter == author;
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            author == 'Panda' ? '🐼' : '🐧',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(author),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          memoryProvider.setFilter(
                            MemoryFilterType.byAuthor,
                            author: author,
                          );
                        } else {
                          memoryProvider.setFilter(MemoryFilterType.newest);
                        }
                        Navigator.pop(context);
                      },
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).colorScheme.secondary,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Clear filters button
              if (memoryProvider.currentFilter != MemoryFilterType.newest ||
                  memoryProvider.authorFilter != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      memoryProvider.clearFilters();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All Filters'),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    MemoryFilterType filterType,
    IconData icon,
  ) {
    final memoryProvider = context.watch<MemoryProvider>();
    final isSelected =
        memoryProvider.currentFilter == filterType &&
        memoryProvider.authorFilter == null;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          memoryProvider.setFilter(filterType);
        } else {
          memoryProvider.setFilter(MemoryFilterType.newest);
        }
        Navigator.pop(context);
      },
      selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.secondary,
    );
  }

  void _navigateToAddMemory() {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isSignedIn) {
      _showAuthRequiredDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemoryScreen(userRole: _userRole),
      ),
    );
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(_userRole == 'Panda' ? '🐼' : '🐧'),
            const SizedBox(width: 8),
            const Text('Sign In Required'),
          ],
        ),
        content: const Text(
          'You need to sign in with Google to create and save memories. This helps us keep your precious moments safe in the cloud!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }
}
