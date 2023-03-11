import 'package:flutter/material.dart';
import 'package:streaming_app/screens/browse_screen.dart';
import 'package:streaming_app/screens/feed_screen.dart';
import 'package:streaming_app/screens/golive_screen.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return (Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            selectedIcon: Icon(Icons.favorite),
            icon: Icon(Icons.favorite_outline),
            label: 'Following',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.add),
            icon: Icon(Icons.add_outlined),
            label: 'Go Live',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.explore),
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
        ],
      ),
      body: const [
        FeedScreen(),
        GoLiveScreen(),
        BrowseScreen(),
      ][_selectedPageIndex],
    ));
  }
}
