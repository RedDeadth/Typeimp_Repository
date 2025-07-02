// lib/View/HomeScreen.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'AuthScreen.dart';
import 'dart:convert';
import 'Note.dart';
import 'NoteDetailScreen.dart';
import '../utils/app_constants.dart';
import 'package:typeimp_tecsuproject01/View/_NoteCard.dart';
import 'package:typeimp_tecsuproject01/View/_HomeDrawer.dart';
import 'package:typeimp_tecsuproject01/View/_HomeAppBar.dart';

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
  String _userName = 'Cargando...';
  Color _backgroundColor = Colors.grey[50]!;

  Set<String> _loadingNoteIds = {};

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _fetchUserName();
    _searchController.addListener(() {
      setState(() {
        // Forzar reconstrucción cuando cambia el texto de búsqueda
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    try {
      final userAttributes = await Amplify.Auth.fetchUserAttributes();
      String displayName = 'Usuario';

      for (var attribute in userAttributes) {
        if (attribute.userAttributeKey.key == 'name') {
          displayName = attribute.value;
          break;
        }
      }

      if (displayName == 'Usuario') {
        for (var attribute in userAttributes) {
          if (attribute.userAttributeKey.key == 'preferred_username') {
            displayName = attribute.value;
            break;
          }
        }
      }

      if (displayName == 'Usuario') {
        for (var attribute in userAttributes) {
          if (attribute.userAttributeKey.key == 'email') {
            displayName = attribute.value;
            break;
          }
        }
      }

      if (displayName == 'Usuario') {
          final user = await Amplify.Auth.getCurrentUser();
          displayName = user.username;
      }

      int atIndex = displayName.indexOf('@');
      if (atIndex != -1) { // Si se encuentra un '@'
        displayName = displayName.substring(0, atIndex);
      }

      if (mounted) {
        setState(() {
          _userName = displayName;
        });
      }
    } on AuthException catch (e) {
      safePrint('Error al obtener los atributos del usuario: ${e.message}');
      if (mounted) {
        setState(() {
          _userName = 'Error';
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
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const NoteDetailScreen(note: null),
      ),
    );

    if (result != null) {
      final title = result['title'] as String;
      final content = result['content'] as String;
      final categoryId = result['categoryId'] as String;

      try {
        final payload = {
          'title': title,
          'content': content,
          'categoryId': categoryId,
        };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Creando nota...', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.blueAccent),
        );

        final restOperation = Amplify.API.post(
          '/notes',
          apiName: 'notesApi',
          body: HttpPayload.json(payload),
        );
        final response = await restOperation.response;
        safePrint('POST /notes response: ${response.statusCode} - ${response.decodeBody()}');
        if (!mounted) return;
        if (response.statusCode == 201) {
          final Map<String, dynamic> responseBody = jsonDecode(response.decodeBody());
          final Note newNote = Note.fromJson(responseBody['note']);
          setState(() {
            _notes.insert(0, newNote);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            // CAMBIO DE TEXTO AQUÍ
            const SnackBar(content: Text('¡Nota creada con éxito! ✨', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF28A745)),
          );
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

  Future<void> _editNote(Note originalNote) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: originalNote),
      ),
    );

    if (result != null) {
      final updatedTitle = result['title'] as String;
      final updatedContent = result['content'] as String;
      final updatedCategory = result['categoryId'] as String;
      final noteId = result['noteId'] as String;

      if (!mounted) return;
      setState(() {
        _loadingNoteIds.add(noteId);
      });

      try {
        final payload = {
          'title': updatedTitle,
          'content': updatedContent,
          'categoryId': updatedCategory,
        };

        final restOperation = Amplify.API.put(
          '/notes/$noteId',
          apiName: 'notesApi',
          body: HttpPayload.json(payload),
        );
        final response = await restOperation.response;
        safePrint('PUT /notes/$noteId response: ${response.statusCode} - ${response.decodeBody()}');
        if (!mounted) return;
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseBody = jsonDecode(response.decodeBody());
          final Note updatedNote = Note.fromJson(responseBody['note']);
          setState(() {
            final index = _notes.indexWhere((n) => n.noteId == updatedNote.noteId);
            if (index != -1) {
              _notes[index] = updatedNote;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Nota actualizada con éxito! 🎉', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF28A745)),
          );
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
      } finally {
        if (mounted) {
          setState(() {
            _loadingNoteIds.remove(noteId);
          });
        }
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Color(0xFF1A1A1A))),
        // CAMBIO DE TEXTO AQUÍ
        content: const Text('¿Estás seguro de que quieres eliminar esta nota? ¡Se irá para siempre!', style: TextStyle(color: Color(0xFF333333))),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF333333)),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Open Sans')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF233C)),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() {
        _loadingNoteIds.add(noteId);
      });

      try {
        final restOperation = Amplify.API.delete(
          '/notes/$noteId',
          apiName: 'notesApi',
        );
        final response = await restOperation.response;
        safePrint('DELETE /notes/$noteId response: ${response.statusCode} - ${response.decodeBody()}');
        if (!mounted) return;
        if (response.statusCode == 200) {
          setState(() {
            _notes.removeWhere((note) => note.noteId == noteId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Nota eliminada con éxito! Adiós, idea. 👋', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF28A745)),
          );
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
      } finally {
        if (mounted) {
          setState(() {
            _loadingNoteIds.remove(noteId);
          });
        }
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
      drawer: HomeDrawer(
        userName: _userName,
        isDarkMode: isDarkMode,
        onSignOut: () => _signOut(context),
        onToggleTheme: _toggleBackgroundColor,
      ),
      // --- FloatingActionButton AÑADIDO AQUÍ ---
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: const Color(0xFFFF3B30),
        child: const Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), // Hazlo más redondo
        ),
        elevation: 6.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Colócalo en la esquina inferior derecha
      // --- FIN FloatingActionButton ---
      body: Column(
        children: [
          HomeAppBar(
            searchController: _searchController,
            selectedCategory: _selectedCategory,
            onCategoryChanged: (newValue) {
              setState(() {
                _selectedCategory = newValue!;
              });
            },
            // onAddNote: _addNote, // YA NO NECESARIO AQUÍ
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            searchBarColor: searchBarColor,
            dropdownIconColor: dropdownIconColor,
            topBarColor: topBarColor,
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
                                  // CAMBIO DE TEXTO AQUÍ
                                  'Crea una nueva nota con el botón "+".',
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

                            final bool isNoteLoading = _loadingNoteIds.contains(note.noteId);

                            return NoteCard(
                              note: note,
                              onEdit: _editNote,
                              onDelete: _deleteNote,
                              cardColor: cardColor,
                              displayCategory: mapCategoryToUI(note.categoryId),
                              isDarkMode: isDarkMode,
                              userName: _userName,
                              isLoading: isNoteLoading,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}