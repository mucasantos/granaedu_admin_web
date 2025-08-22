import 'package:flutter/material.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/forms/tag_form.dart';
import 'package:lms_admin/models/tag.dart';

class TagsDropdown extends StatelessWidget {
  const TagsDropdown({
    Key? key,
    required this.selectedTagIDs,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  final List selectedTagIDs;
  final List<Tag> tags;
  final Function onAdd;
  final Function onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 15, right: 15),
              decoration:
                  BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(0)),
              child: DropdownButton(
                hint: const Text('Select Tags'),
                underline: Container(),
                onChanged: (value) => onAdd(value),
                items: tags.map((f) {
                  return DropdownMenuItem(
                    enabled: !selectedTagIDs.contains(f.id),
                    value: f.id,
                    child: Text(f.name),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 15),
            CustomButtons.circleButton(
              context,
              icon: Icons.add,
              bgColor: Theme.of(context).primaryColor,
              iconColor: Colors.white,
              onPressed: () {
                CustomDialogs.openResponsiveDialog(context, widget: const TagForm(tag: null, shouldRefresh: true));
              },
            )
          ],
        ),
        const SizedBox(
          height: 15,
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tags.where((element) => selectedTagIDs.contains(element.id)).map((e) {
            return Chip(
              padding: const EdgeInsets.all(10),
              elevation: 0,
              onDeleted: () => onRemove(e.id),
              deleteIcon: const Icon(
                Icons.clear,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                e.name,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        )
      ],
    );
  }
}
