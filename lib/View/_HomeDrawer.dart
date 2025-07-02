import 'package:flutter/material.dart';
// No hay otras importaciones de paquetes necesarias en este archivo por ahora,
// ya que no usa Note.dart ni app_constants directamente, solo Material.

class HomeDrawer extends StatelessWidget {
  final String userName;
  final bool isDarkMode;
  final VoidCallback onSignOut;
  final VoidCallback onToggleTheme;

  const HomeDrawer({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.onSignOut,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF333333),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 40, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¡Hola,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  Text(
                    '$userName!',
//                    'Bienvenido crack!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.notes,
              text: 'Mis Notas',
              isSelected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.archive,
              text: 'Archivadas',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad de Archivadas pendiente.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              text: 'Configuración',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad de Configuración pendiente.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
              },
            ),
            _buildDrawerItem(
              icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
              text: isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
              onTap: () {
                onToggleTheme();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 50),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontFamily: 'Open Sans')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF233C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      color: isSelected ? const Color(0xFFFF3B30).withOpacity(0.3) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : const Color(0xFFCCCCCC)),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFCCCCCC),
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Open Sans',
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}