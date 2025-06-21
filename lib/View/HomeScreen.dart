import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'AuthScreen.dart';
import 'dart:convert';
import 'Note.dart'; // Asume que tienes un archivo Note.dart con la clase Note

// --- Extensión para oscurecer/aclarar colores (mantener) ---
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
// --- Fin de extensión ---

const List<String> kNoteCategoriesUI = [
  'Todas las Notas',
  'Trabajo',
  'Personal',
  'Ideas',
  'Recordatorios',
];

String mapCategoryToBackend(String uiCategory) {
  switch (uiCategory) {
    case 'Trabajo':
      return 'Work';
    case 'Recordatorios':
      return 'Uncategorized';
    case 'Todas las Notas':
      return 'All';
    default:
      return uiCategory;
  }
}

String mapCategoryToUI(String backendCategory) {
  switch (backendCategory) {
    case 'Work':
      return 'Trabajo';
    case 'Personal':
      return 'Personal';
    case 'Ideas':
      return 'Ideas';
    case 'Uncategorized':
      return 'Recordatorios';
    default:
      return 'Sin Categoría';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;
  String _selectedCategory = kNoteCategoriesUI[0];
  final TextEditingController _searchController = TextEditingController();
  String _userName = 'Usuario Genial';
  Color _backgroundColor = Colors.grey[50]!;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _fetchUserName();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (mounted) {
        setState(() {
          _userName = user.username;
        });
      }
    } on AuthException catch (e) {
      safePrint('Error al obtener el usuario actual: ${e.message}');
      if (mounted) {
        setState(() {
          _userName = 'Usuario';
        });
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } on AuthException catch (e) {
      safePrint('Error al cerrar sesión: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.message}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
      );
    }
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final restOperation = Amplify.API.get(
        '/notes',
        apiName: 'notesApi',
      );
      final response = await restOperation.response;
      safePrint('GET /notes response: ${response.statusCode} - ${response.decodeBody()}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.decodeBody());
        final List<dynamic> notesJson = responseBody['notes'];
        if (!mounted) return;
        setState(() {
          _notes = notesJson.map((json) => Note.fromJson(json)).toList();
          _notes.sort((a, b) {
            final DateTime dateA = DateTime.parse(a.createdAt);
            final DateTime dateB = DateTime.parse(b.createdAt);
            return dateB.compareTo(dateA);
          });
        });
      } else {
        safePrint('Failed to load notes: ${response.statusCode}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar notas: ${response.statusCode}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
        );
      }
    } on ApiException catch (e) {
      safePrint('GET failed: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de API al cargar notas: ${e.message}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNote() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const AddEditNoteDialog(
        initialTitle: '',
        initialContent: '',
        initialCategory: 'Recordatorios', // Default category
        isEdit: false,
      ),
    );

    if (result != null) {
      try {
        final backendCategory = mapCategoryToBackend(result['categoryId']!);
        final payload = {
          'title': result['title'],
          'content': result['content'],
          'categoryId': backendCategory,
        };

        final restOperation = Amplify.API.post(
          '/notes',
          apiName: 'notesApi',
          body: HttpPayload.json(payload),
        );
        final response = await restOperation.response;
        safePrint('POST /notes response: ${response.statusCode} - ${response.decodeBody()}');
        if (!mounted) return;
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Nota brillante creada con éxito! ✨', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF28A745)),
          );
          _fetchNotes();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear nota: ${response.decodeBody()}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
          );
        }
      } on ApiException catch (e) {
        safePrint('POST failed: ${e.message}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API al crear nota: ${e.message}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
        );
      }
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddEditNoteDialog(
        initialTitle: note.title,
        initialContent: note.content,
        initialCategory: mapCategoryToUI(note.categoryId),
        isEdit: true,
      ),
    );

    if (result != null) {
      try {
        final backendCategory = mapCategoryToBackend(result['categoryId']!);
        final payload = {
          'title': result['title'],
          'content': result['content'],
          'categoryId': backendCategory,
        };

        final restOperation = Amplify.API.put(
          '/notes/${note.noteId}',
          apiName: 'notesApi',
          body: HttpPayload.json(payload),
        );
        final response = await restOperation.response;
        safePrint('PUT /notes/${note.noteId} response: ${response.statusCode} - ${response.decodeBody()}');
        if (!mounted) return;
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Nota actualizada con éxito! 🎉', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF28A745)),
          );
          _fetchNotes();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar nota: ${response.decodeBody()}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
          );
        }
      } on ApiException catch (e) {
        safePrint('PUT failed: ${e.message}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API: ${e.message}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Color(0xFF1A1A1A))),
        content: const Text('¿Estás seguro de que quieres eliminar esta nota brillante? ¡Se irá para siempre!', style: TextStyle(color: Color(0xFF333333))),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF333333)),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Open Sans')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF233C)), // Rojo para eliminar
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final restOperation = Amplify.API.delete(
          '/notes/$noteId',
          apiName: 'notesApi',
        );
        final response = await restOperation.response;
        safePrint('DELETE /notes/$noteId response: ${response.statusCode} - ${response.decodeBody()}');
        if (!mounted) return;
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Nota eliminada con éxito! Adiós, idea. 👋', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF28A745)),
          );
          _fetchNotes();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar nota: ${response.decodeBody()}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
          );
        }
      } on ApiException catch (e) {
        safePrint('DELETE failed: ${e.message}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API: ${e.message}', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFEF233C)),
        );
      }
    }
  }

  List<Note> get _filteredNotes {
    List<Note> notesToFilter = _notes;

    if (_selectedCategory != kNoteCategoriesUI[0]) {
      final backendCategory = mapCategoryToBackend(_selectedCategory);
      notesToFilter = notesToFilter
          .where((note) => note.categoryId == backendCategory)
          .toList();
    }

    final String searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      notesToFilter = notesToFilter.where((note) {
        return note.title.toLowerCase().contains(searchQuery) ||
               note.content.toLowerCase().contains(searchQuery);
      }).toList();
    }

    return notesToFilter;
  }

  // Función para cambiar el color de fondo
  void _toggleBackgroundColor() {
    setState(() {
      _backgroundColor = _backgroundColor == Colors.grey[50] ? Colors.grey[900]! : Colors.grey[50]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.8;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.9;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 1.0;
    }

    final bool isDarkMode = _backgroundColor == Colors.grey[900];
    final Color primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    final Color secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color searchBarColor = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
    final Color dropdownIconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color topBarColor = isDarkMode ? Colors.grey[850]! : Colors.white;

    return Scaffold(
      backgroundColor: _backgroundColor,
      drawer: Drawer(
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
                    // AQUÍ ESTÁ LA CORRECCIÓN PARA EL DESBORDAMIENTO DEL USUARIO
                    Text(
                      '$_userName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                      maxLines: 1, // Limita a una línea
                      overflow: TextOverflow.ellipsis, // Añade puntos suspensivos si se desborda
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
                  _toggleBackgroundColor();
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _signOut(context),
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
      ),
      body: Column(
        children: [
          Container(
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
                      Text(
                        'Tus Ideas Brillantes',
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
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            color: searchBarColor,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: primaryTextColor.withOpacity(0.2), width: 1),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar notas divertidas...',
                              hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: dropdownIconColor),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                            style: TextStyle(fontFamily: 'Open Sans', color: primaryTextColor),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addNote,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Nueva Nota', style: TextStyle(color: Colors.white, fontFamily: 'Open Sans')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: searchBarColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: primaryTextColor.withOpacity(0.2), width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            icon: Icon(Icons.arrow_drop_down, color: dropdownIconColor),
                            style: TextStyle(color: primaryTextColor, fontSize: 16, fontFamily: 'Open Sans'),
                            dropdownColor: cardBackgroundColor,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                              });
                            },
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
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30)))
                : _filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No se encontraron notas con esa búsqueda.'
                                  : '¡No tienes notas en esta categoría!',
                              style: TextStyle(fontSize: 18, color: secondaryTextColor, fontFamily: 'Open Sans'),
                            ),
                            if (_searchController.text.isEmpty && _selectedCategory == kNoteCategoriesUI[0])
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Crea una nueva idea brillante con el botón "+ Nueva Nota".',
                                  style: TextStyle(fontSize: 16, color: secondaryTextColor.withOpacity(0.8), fontFamily: 'Open Sans'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            Color cardColor;
                            switch (note.categoryId) {
                              case 'Work':
                                cardColor = const Color(0xFF2E8B57).lighten(0.3);
                                break;
                              case 'Personal':
                                cardColor = const Color(0xFF4682B4).lighten(0.3);
                                break;
                              case 'Ideas':
                                cardColor = const Color(0xFFDAA520).lighten(0.3);
                                break;
                              case 'Uncategorized':
                                cardColor = const Color(0xFF9370DB).lighten(0.3);
                                break;
                              default:
                                cardColor = Colors.grey.shade100;
                            }

                            return NoteCard(
                              note: note,
                              onEdit: _editNote,
                              onDelete: _deleteNote,
                              cardColor: cardColor,
                              displayCategory: mapCategoryToUI(note.categoryId),
                              isDarkMode: isDarkMode,
                              userName: _userName,
                            );
                          },
                        ),
                      ),
          ),
        ],
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

// Clase NoteCard (REVERTIDA a su estado anterior, antes de las últimas modificaciones)
class NoteCard extends StatelessWidget {
  final Note note;
  final Function(Note) onEdit;
  final Function(String) onDelete;
  final Color cardColor;
  final String displayCategory;
  final bool isDarkMode;
  final String userName; // Mantenemos este parámetro para flexibilidad si lo quieres usar después

  const NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.cardColor,
    required this.displayCategory,
    this.isDarkMode = false,
    required this.userName, // Sigue siendo requerido
  });

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    final Color contentColor = isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final Color dateColor = isDarkMode ? Colors.grey[500]! : Colors.grey[500]!;
    final Color cardBorderColor = isDarkMode ? cardColor.darken(0.3) : cardColor.darken(0.1);
    final Color cardBackground = isDarkMode ? Colors.grey[850]! : Colors.white;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: cardBorderColor,
          width: 2,
        ),
      ),
      color: cardBackground,
      child: InkWell(
        onTap: () {
          // Puedes implementar una acción al tocar la tarjeta si deseas, como ver detalles
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: cardColor.darken(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                note.title, // Volvemos a usar el título real de la nota
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  fontFamily: 'Montserrat',
                ),
                maxLines: 1, // Aseguramos que no se desborde el título
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content, // Volvemos a usar el contenido real de la nota
                  style: TextStyle(fontSize: 14, color: contentColor, fontFamily: 'Open Sans'),
                  maxLines: 2, // Aseguramos que no se desborde el contenido
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      note.createdAt.substring(0, 10), // Fecha real de la nota
                      style: TextStyle(fontSize: 12, color: dateColor, fontFamily: 'Open Sans'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onEdit(note),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.edit, size: 20, color: const Color(0xFFFF3B30)),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onDelete(note.noteId),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.delete, size: 20, color: const Color(0xFFEF233C)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase AddEditNoteDialog (sin cambios significativos)
class AddEditNoteDialog extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final String initialCategory;
  final bool isEdit;

  const AddEditNoteDialog({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.initialCategory,
    required this.isEdit,
  });

  @override
  State<AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<AddEditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;

  final List<String> _dialogCategories = kNoteCategoriesUI.where((cat) => cat != 'Todas las Notas').toList();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    if (!_dialogCategories.contains(widget.initialCategory)) {
      _selectedCategory = _dialogCategories.first;
    } else {
      _selectedCategory = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Editar Nota' : 'Añadir Nueva Nota', style: const TextStyle(fontFamily: 'Montserrat', color: Color(0xFF333333))),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  hintText: 'Tu idea brillante aquí...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lightbulb_outline, color: Color(0xFF333333)),
                  labelStyle: const TextStyle(color: Color(0xFF333333)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un título';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF333333)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Contenido',
                  hintText: 'Detalles de tu nota...',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFF333333)),
                  labelStyle: const TextStyle(color: Color(0xFF333333)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
                  ),
                ),
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el contenido de la nota';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF333333)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF333333)),
                  labelStyle: const TextStyle(color: Color(0xFF333333)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
                  ),
                ),
                items: _dialogCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF333333))),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona una categoría';
                  }
                  return null;
                },
                style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF333333)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF333333)),
          child: const Text('Cancelar', style: TextStyle(fontFamily: 'Open Sans')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'content': _contentController.text,
                'categoryId': _selectedCategory,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(widget.isEdit ? 'Guardar Cambios' : 'Añadir Nota', style: const TextStyle(fontFamily: 'Open Sans')),
        ),
      ],
    );
  }
}

class Note {
  final String noteId;
  final String title;
  final String content;
  final String categoryId;
  final String userId;
  final String createdAt;
  final String updatedAt;

  Note({
    required this.noteId,
    required this.title,
    required this.content,
    required this.categoryId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      noteId: json['noteId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      categoryId: json['categoryId'] as String,
      userId: json['userId'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}