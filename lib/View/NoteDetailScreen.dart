import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'Note.dart'; // ¡CORREGIDO! Si Note.dart está en la misma carpeta (lib/View/)
import '../utils/app_constants.dart'; // Importa tus constantes y extensiones

class NoteDetailScreen extends StatefulWidget {
  final Note? note; // Puede ser nulo si es una nueva nota

  const NoteDetailScreen({super.key, this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  bool _isSaving = false; // Estado para el indicador de guardado

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    // Inicializa la categoría seleccionada.
    // Si hay una nota existente, usa su categoría y la mapea a la UI.
    // Si no, usa la primera categoría por defecto de la UI (e.g., "Todas").
    _selectedCategory = widget.note != null
        ? mapCategoryToUI(widget.note!.categoryId)
        : kNoteCategoriesUI[0];

    // Asegúrate de que la categoría seleccionada esté en la lista de UI,
    // si no, usa la primera por defecto para evitar errores.
    if (!kNoteCategoriesUI.contains(_selectedCategory)) {
      _selectedCategory = kNoteCategoriesUI[0];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Función para guardar o actualizar la nota
  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true; // Muestra el indicador de carga
    });

    final String title = _titleController.text.trim();
    final String content = _contentController.text.trim();
    final String categoryId = mapCategoryToBackend(_selectedCategory);

    // Validación básica
    if (title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título de la nota no puede estar vacío.', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFFEF233C),
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    // Devuelve los datos a HomeScreen
    if (!mounted) return;
    Navigator.of(context).pop({
      'noteId': widget.note?.noteId, // Solo si estamos editando
      'title': title,
      'content': content,
      'categoryId': categoryId,
    });

    // Nota: La lógica de llamada a la API (POST/PUT) se ha movido a HomeScreen
    // para centralizar el manejo de las listas y los estados de loading.
    // Aquí solo preparamos los datos y los pasamos de vuelta.
  }

  // Diálogo de confirmación antes de salir si hay cambios
  Future<bool> _onWillPop() async {
    final bool hasChanges = _titleController.text.trim() != (widget.note?.title ?? '') ||
                            _contentController.text.trim() != (widget.note?.content ?? '') ||
                            mapCategoryToBackend(_selectedCategory) != (widget.note?.categoryId ?? mapCategoryToBackend(kNoteCategoriesUI[0]));

    if (hasChanges && !_isSaving) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descartar cambios?', style: TextStyle(color: Color(0xFF1A1A1A))),
          content: const Text('Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?', style: TextStyle(color: Color(0xFF333333))),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF333333)),
              child: const Text('No, quedarme', style: TextStyle(fontFamily: 'Open Sans')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF233C)),
              child: const Text('Sí, salir', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return confirm ?? false; // Retorna true si se confirma salir, false si se cancela
    }
    return true; // Si no hay cambios o ya se está guardando, permite salir directamente
  }

  @override
  Widget build(BuildContext context) {
    final bool isCreatingNewNote = widget.note == null;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark; // Detecta el modo oscuro del tema
    final Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
    final Color appBarColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    final Color secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color inputFillColor = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
    final Color dropdownColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color borderColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;


    return PopScope( // Para manejar el botón de retroceso (Android)
      canPop: false, // Controlamos el pop manualmente
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop(null); // Pasa null para indicar que no se guardó
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryTextColor),
            onPressed: () async {
              final bool shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop(null); // Pasa null para indicar que no se guardó
              }
            },
          ),
          title: Text(
            isCreatingNewNote ? 'Nueva Nota' : 'Editar Nota',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Color(0xFFFF3B30))
                  : ElevatedButton.icon(
                      onPressed: _saveNote,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Guardar', style: TextStyle(color: Colors.white, fontFamily: 'Open Sans')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 3,
                      ),
                    ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Campo de Título
              TextField(
                controller: _titleController,
                style: TextStyle(color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                decoration: InputDecoration(
                  hintText: 'Título de tu Nota...',
                  hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none, // Sin borde visible por defecto
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFFF3B30).lighten(0.1), width: 2), // Borde cuando está enfocado
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor, width: 1), // Borde cuando no está enfocado
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                cursorColor: const Color(0xFFFF3B30),
                maxLines: 1,
              ),
              const SizedBox(height: 16),

              // Selector de Categoría
              Container(
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    icon: Icon(Icons.arrow_drop_down, color: secondaryTextColor),
                    style: TextStyle(color: primaryTextColor, fontSize: 16, fontFamily: 'Open Sans'),
                    dropdownColor: dropdownColor,
                    decoration: InputDecoration(
                      border: InputBorder.none, // Elimina el borde de DropdownButtonFormField
                      contentPadding: EdgeInsets.zero, // Ajusta el padding si es necesario
                    ),
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
              const SizedBox(height: 16),

              // Campo de Contenido
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: TextStyle(color: primaryTextColor, fontSize: 16, fontFamily: 'Open Sans'),
                  decoration: InputDecoration(
                    hintText: 'Desarrolla tu Nota aquí...',
                    hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFFF3B30).lighten(0.1), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    alignLabelWithHint: true, // Alinea el hint en la parte superior para multilínea
                  ),
                  cursorColor: const Color(0xFFFF3B30),
                  maxLines: null, // Permite múltiples líneas
                  expands: true, // Permite que el TextField ocupe el espacio disponible
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top, // Alinea el texto al inicio verticalmente
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}