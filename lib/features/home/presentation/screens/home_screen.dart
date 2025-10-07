import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../gratitude/presentation/screens/add_gratitude_bottom_sheet.dart';
import '../../../gratitude/presentation/screens/map_screen.dart';

/// Home screen with map and gratitude feed
/// 
/// Main screen showing:
/// - Interactive map with gratitude markers
/// - Feed of gratitudes (All/My)
/// - Button to add new gratitude
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<LatLng?> _selectedMapLocation = ValueNotifier<LatLng?>(null);
  final ValueNotifier<bool> _isSelectingLocation = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _selectedMapLocation.dispose();
    _isSelectingLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ripple'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () {
              // TODO: Navigate to achievements
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MapScreen(
            selectedLocationNotifier: _selectedMapLocation,
            isSelectingLocationNotifier: _isSelectingLocation,
          ),
          const _FeedView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted),
            selectedIcon: Icon(Icons.format_list_bulleted_outlined),
            label: 'Feed',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddGratitudeBottomSheet(
            context,
            selectedLocationNotifier: _selectedMapLocation,
            isSelectingLocationNotifier: _isSelectingLocation,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Thanks'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _FeedView extends StatelessWidget {
  const _FeedView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.format_list_bulleted, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Feed View',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'TODO: Implement gratitude feed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
