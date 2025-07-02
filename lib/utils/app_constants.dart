import 'package:flutter/material.dart';

// --- Extensión para oscurecer/aclarar colores ---
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

// --- Categorías de notas para la UI ---
const List<String> kNoteCategoriesUI = [
  'Todas las Notas',
  'Trabajo',
  'Personal',
  'Ideas',
  'Recordatorios',
];

// --- Mapeo de categorías UI a Backend ---
String mapCategoryToBackend(String uiCategory) {
  switch (uiCategory) {
    case 'Trabajo':
      return 'Work';
    case 'Recordatorios':
      return 'Uncategorized';
    case 'Todas las Notas': // Esto no debería usarse para POST/PUT, es solo para filtrado en UI
      return 'All'; // O un valor que tu backend entienda para "todas"
    default:
      return uiCategory; // Asume que si no coincide, el nombre de UI es el mismo que en backend
  }
}

// --- Mapeo de categorías Backend a UI ---
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
    case 'All': // Si tu backend devuelve "All" para alguna nota (no común), mapearlo
      return 'Todas las Notas';
    default:
      return 'Sin Categoría'; // Si el backend tiene una categoría desconocida
  }
}