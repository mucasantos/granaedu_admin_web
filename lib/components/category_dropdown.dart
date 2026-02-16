import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/categories_provider.dart';

class CategoryDropdown extends ConsumerWidget {
  const CategoryDropdown({
    Key? key,
    required this.selectedCategoryId,
    required this.onChanged,
    this.title,
    this.hasClearButton,
    this.onClearSelection,
  }) : super(key: key);

  final String? selectedCategoryId;
  final Function onChanged;
  final String? title;
  final bool? hasClearButton;
  final Function? onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    // Checking the selected category is not deleted. If deleted, the value should be null;
    final String? selectedId = selectedCategoryId == null
        ? null
        : categories.where((element) => element.id == selectedCategoryId).isEmpty
            ? null
            : selectedCategoryId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? 'Category *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          padding: const EdgeInsets.only(left: 15, right: 15),
          decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(0)),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(border: InputBorder.none),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Category is required';
                    return null;
                  },
                  onChanged: (dynamic value) => onChanged(value),
                  initialValue: selectedId,
                  hint: const Text('Select Category'),
                  items: categories.map((f) {
                    return DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name),
                    );
                  }).toList(),
                ),
              ),
              Visibility(
                visible: hasClearButton ?? false,
                child: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear selection',
                  onPressed: () => onClearSelection!(),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
