// lib/View/_HomeAppBar.dart
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  // final VoidCallback onAddNote; // YA NO NECESARIO AQUÍ
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color searchBarColor;
  final Color dropdownIconColor;
  final Color topBarColor;

  const HomeAppBar({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    // required this.onAddNote, // YA NO NECESARIO AQUÍ
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.searchBarColor,
    required this.dropdownIconColor,
    required this.topBarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: topBarColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, color: primaryTextColor, size: 30),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // CAMBIO DE TEXTO AQUÍ
                Text(
                  'Tus Notas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    // margin: const EdgeInsets.only(right: 8.0), // Este margen puede ser innecesario ahora
                    decoration: BoxDecoration(
                      color: searchBarColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: primaryTextColor.withOpacity(0.2), width: 1),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar notas divertidas...',
                        hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: dropdownIconColor),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      ),
                      onChanged: (value) {
                        // Este onChanged ya está conectado al _searchController
                        // El setState en HomeScreen lo capturará
                      },
                      style: TextStyle(fontFamily: 'Open Sans', color: primaryTextColor),
                    ),
                  ),
                ),
                // --- BOTÓN ELIMINADO AQUÍ ---
                // ElevatedButton.icon(
                //   onPressed: onAddNote,
                //   icon: const Icon(Icons.add, color: Colors.white),
                //   label: const Text('Nueva Nota', style: TextStyle(color: Colors.white, fontFamily: 'Open Sans')),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: const Color(0xFFFF3B30),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(25),
                //     ),
                //     elevation: 5,
                //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //   ),
                // ),
                // const SizedBox(width: 8), // Este espacio puede ser innecesario ahora
                // --- FIN BOTÓN ELIMINADO ---
                Container(
                  decoration: BoxDecoration(
                    color: searchBarColor,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: primaryTextColor.withOpacity(0.2), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      icon: Icon(Icons.arrow_drop_down, color: dropdownIconColor),
                      style: TextStyle(color: primaryTextColor, fontSize: 16, fontFamily: 'Open Sans'),
                      dropdownColor: topBarColor,
                      onChanged: onCategoryChanged,
                      items: kNoteCategoriesUI.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(fontFamily: 'Open Sans', color: primaryTextColor)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(130.0);
}