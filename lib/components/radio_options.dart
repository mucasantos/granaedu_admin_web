import 'package:flutter/material.dart';

class RadioOptions extends StatelessWidget {
  const RadioOptions({
    super.key,
    required this.contentType,
    required this.onChanged,
    required this.options,
    required this.title,
    required this.icon,
  });

  final String contentType;
  final Function onChanged;
  final Map<String, String> options;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(
          width: 5,
        ),
        Text('$title : '),
        const SizedBox(
          width: 10,
        ),
        Wrap(
          children: options.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Radio(
                    value: e.key,
                    groupValue: contentType,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (value) => onChanged(value),
                  ),
                  Text(e.value)
                ],
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}
