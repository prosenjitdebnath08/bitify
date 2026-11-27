import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/theme_color_service.dart';
import '../state/music_player_state.dart';
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
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(state: widget.state),
      ExploreScreen(state: widget.state),
      SearchScreen(state: widget.state),
      LibraryScreen(state: widget.state),
      SettingsScreen(state: widget.state),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenContent = IndexedStack(
      index: _currentIndex,
      children: _pages,
    );

    return AnimatedBuilder(
      animation: ThemeColorService(),
      builder: (context, child) {
        final p = ThemeColorService().palette;

        return Scaffold(
          backgroundColor: p.background,
          body: Stack(
            children: [
              // Screen content kept stable across player state notifications
              child!,

              // Bottom floating mini player + neumorphic navigation bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Persistent Mini Player (listens internally)
                      MiniPlayerBar(state: widget.state),

                      // Neumorphic Frosted Bottom Nav isolated in RepaintBoundary
                      RepaintBoundary(
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: p.surface.withOpacity(0.92),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withOpacity(0.45),
                                    width: 1.0,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: p.shadowDark.withOpacity(0.4),
                                    offset: const Offset(0, -4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildNavItem(0, Icons.home_rounded, 'Home', p),
                                  _buildNavItem(1, Icons.explore_rounded, 'Explore', p),
                                  _buildNavItem(2, Icons.search_rounded, 'Search', p),
                                  _buildNavItem(3, Icons.library_music_rounded, 'Library', p),
                                  _buildNavItem(4, Icons.settings_rounded, 'Settings', p),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: screenContent,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, SongColorPalette p) {
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
          color: isSelected ? p.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? p.primary : p.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? p.primary : p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
