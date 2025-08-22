import 'package:flutter/material.dart';
import 'package:lms_admin/services/app_service.dart';

mixin TextFields {
  Widget buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required String title,
    bool hasImageUpload = false,
    VoidCallback? onPickImage,
    bool? isPassword,
    bool validationRequired = true,
    bool urlValidationRequired = false,
    int? minLines,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          color: Colors.grey.shade200,
          child: TextFormField(
            maxLines: maxLines,
            minLines: minLines,
            obscureText: isPassword ?? false,
            controller: controller,
            validator: (value) {
              if (validationRequired && value!.isEmpty) return 'value is empty';
              if(urlValidationRequired && !AppService.isURLValid(value!)) return 'Invalid Url'; 
              return null;
            },
            decoration: InputDecoration(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => controller.clear(),
                    icon: const Icon(Icons.clear),
                  ),
                  Visibility(
                    visible: hasImageUpload,
                    child: IconButton(
                      tooltip: 'Select Image',
                      icon: const Icon(Icons.image_outlined),
                      onPressed: onPickImage,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  )
                ],
              ),
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSearchTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required Function onSubmitted,
    required Function onClear,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      child: TextFormField(
        controller: controller,
        onFieldSubmitted: (value) => onSubmitted(value),
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () => onClear(),
            icon: const Icon(Icons.clear),
          ),
          hintText: hint,
          border: InputBorder.none,
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        ),
      ),
    );
  }

  Widget actionTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required String title,
    required List list,
    required Function onSubmitted,
    required Function onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          color: Colors.grey.shade200,
          child: TextFormField(
            controller: controller,
            onFieldSubmitted: (value) => onSubmitted(value),
            decoration: InputDecoration(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onSubmitted(controller.text),
                    icon: const Icon(Icons.send),
                  ),
                  const SizedBox(
                    width: 10,
                  )
                ],
              ),
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
            ),
          ),
        ),
        Column(
          children: list.map((e) {
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  leading: const Icon(Icons.done),
                  title: Text(e),
                  trailing: IconButton(
                    onPressed: () => onDelete(e),
                    icon: const Icon(Icons.clear),
                  ),
                ),
                const Divider()
              ],
            );
          }).toList(),
        )
      ],
    );
  }
}
