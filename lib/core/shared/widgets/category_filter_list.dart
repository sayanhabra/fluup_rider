import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class CategoryFilterList<T> extends ConsumerWidget {
  const CategoryFilterList({
    super.key,
    required this.items,
    required this.selectedItemProvider,
    required this.labelBuilder,
    this.padding,
    this.height = 40,
    this.spacing = 11,
    this.selectedColor = const Color(0xFF5E6162),
    this.unselectedColor = const Color(0xFFF1F1F1),
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
    this.borderColor = const Color(0xFFDADADA),
    this.borderRadius = 10,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.onChanged,
    this.isSameItem,
  });

  /// Any type of list:
  /// String, int, enum, model, etc.
  final List<T> items;

  /// Stores the currently selected item.
  final StateProvider<T?> selectedItemProvider;

  /// Converts an item into display text.
  ///
  /// Example:
  /// (item) => item.name
  final String Function(T item) labelBuilder;

  /// Optional custom comparison.
  ///
  /// Useful when API models are recreated and object references differ.
  final bool Function(T item, T selectedItem)? isSameItem;

  /// Optional callback when selection changes.
  final ValueChanged<T>? onChanged;

  final EdgeInsetsGeometry? padding;
  final double height;
  final double spacing;

  final Color selectedColor;
  final Color unselectedColor;

  final Color selectedTextColor;
  final Color unselectedTextColor;

  final Color borderColor;
  final double borderRadius;

  final EdgeInsetsGeometry itemPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = ref.watch(selectedItemProvider);

    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) {
          return SizedBox(width: spacing);
        },
        itemBuilder: (context, index) {
          final item = items[index];

          final isSelected = _isSelected(item, selectedItem);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(selectedItemProvider.notifier).state = item;

                onChanged?.call(item);
              },
              borderRadius: BorderRadius.circular(borderRadius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: itemPadding,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isSelected ? selectedColor : borderColor,
                  ),
                  color: isSelected ? selectedColor : unselectedColor,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(labelBuilder(item)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSelected(T item, T? selectedItem) {
    if (selectedItem == null) {
      return false;
    }

    // Use custom comparison when provided.
    if (isSameItem != null) {
      return isSameItem!(item, selectedItem);
    }

    // Default object equality.
    return item == selectedItem;
  }
}








//====================================================
// class Category {
//   final int id;
//   final String name;

//   Category({
//     required this.id,
//     required this.name,
//   });
// }


// final selectedCategoryProvider =
//     StateProvider<Category?>(
//   (ref) => null,
// );


// CategoryFilterList<Category>(
//   items: categoryList,
//   selectedItemProvider:
//       selectedCategoryProvider,

//   // What should be displayed?
//   labelBuilder: (category) {
//     return category.name;
//   },

//   // Compare models using unique ID.
//   isSameItem: (item, selected) {
//     return item.id == selected.id;
//   },

//   onChanged: (category) {
//     debugPrint(
//       'Category ID: ${category.id}',
//     );

//     // Call filter/API here.
//   },
// )