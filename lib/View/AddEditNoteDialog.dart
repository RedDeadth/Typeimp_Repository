// lib/View/AddEditNoteDialog.dart (o en el mismo archivo si es un widget privado)

import 'package:flutter/material.dart';
import 'package:typeimp_tecsuproject01/View/AppCategory.dart'; // *** IMPORTACIÓN ACTUALIZADA ***

class AddEditNoteDialog extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final String initialCategory; // Ahora será el categoryId
  final bool isEdit;
  final List<AppCategory> availableCategories; // *** CAMBIADO A AppCategory ***

  const AddEditNoteDialog({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.initialCategory,
    required this.isEdit,
    required this.availableCategories,
  });

  @override
  State<AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<AddEditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategoryId; // Almacenará el categoryId seleccionado

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);

    // Si la categoría inicial no está en la lista de disponibles, usar 'Uncategorized'
    // Asegúrate de que 'Uncategorized' esté siempre disponible, ya sea en la lista o como fallback
    final initialCategoryExists = widget.availableCategories.any(
      (cat) => cat.categoryId == widget.initialCategory || cat.name == widget.initialCategory // Comprobar por ID o por nombre si es un valor legacy
    );
    _selectedCategoryId = initialCategoryExists
        ? widget.initialCategory // Si existe, úsala
        : 'Uncategorized'; // Sino, usa el ID de 'Uncategorized'
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construir la lista de DropdownMenuItem a partir de AppCategory objetos
    final List<DropdownMenuItem<String>> categoryDropdownItems = 
        widget.availableCategories.map((AppCategory category) { // *** CAMBIADO A AppCategory ***
      return DropdownMenuItem<String>(
        value: category.categoryId, // El valor es el ID de la categoría
        child: Text(category.name), // Lo que se muestra es el nombre
      );
    }).toList();

    // Añadir la opción 'Sin Categoría' si no existe ya por su ID
    // Esto es vital porque notes puede tener categoryId='Uncategorized'
    if (!widget.availableCategories.any((cat) => cat.categoryId == 'Uncategorized')) { // *** CAMBIADO A AppCategory ***
      categoryDropdownItems.add(
        const DropdownMenuItem<String>(
          value: 'Uncategorized',
          child: Text('Sin Categoría'),
        ),
      );
    }
    
    return AlertDialog(
      title: Text(widget.isEdit ? 'Editar Nota' : 'Añadir Nueva Nota'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un título';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Contenido'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el contenido de la nota';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categoryDropdownItems,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoryId = newValue!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'content': _contentController.text,
                'categoryId': _selectedCategoryId,
              });
            }
          },
          child: Text(widget.isEdit ? 'Guardar Cambios' : 'Añadir Nota'),
        ),
      ],
    );
  }
}
