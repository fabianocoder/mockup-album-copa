import 'package:flutter/material.dart';

import '../features/album/presentation/album_page.dart';
import '../features/album/presentation/spares_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/sharing/presentation/share_page.dart';

/// Casca de navegação principal com as quatro abas do aplicativo.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    AlbumPage(),
    SparesPage(),
    SharePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserva o estado (scroll, filtros) de cada aba.
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: 'Álbum',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Repetidas',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2),
            label: 'Compartilhar',
          ),
        ],
      ),
    );
  }
}
