import 'dart:ui';
import 'package:flutter/material.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final MusicPlayerState state;

  const MainNavigationScreen({super.key, required this.state});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final pages = [
          HomeScreen(state: widget.state),
          ExploreScreen(state: widget.state),
          SearchScreen(state: widget.state),
          LibraryScreen(state: widget.state),
          SettingsScreen(state: widget.state),
        ];

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              // Screen content
              IndexedStack(
                index: _currentIndex,
                children: pages,
              ),

              // Bottom floating mini player + frosted navigation bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Persistent Mini Player (if a track is selected)
                    if (widget.state.currentSong != null)
                      MiniPlayerBar(state: widget.state),

                    // Frosted Glass Bottom Nav
                    ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0E1A).withOpacity(0.85),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.08),
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavItem(0, Icons.home_rounded, 'Home'),
                              _buildNavItem(1, Icons.explore_rounded, 'Explore'),
                              _buildNavItem(2, Icons.search_rounded, 'Search'),
                              _buildNavItem(3, Icons.library_music_rounded, 'Library'),
                              _buildNavItem(4, Icons.settings_rounded, 'Settings'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
