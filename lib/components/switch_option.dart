import 'package:flutter/material.dart';

class SwitchOption extends StatelessWidget {
  const SwitchOption({
    super.key,
    required this.onChanged,
    required this.title,
    required this.deafultValue,
  });

  final Function onChanged;
  final String title;
  final bool deafultValue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        subtitle: Text(deafultValue ? 'Enabled' : 'Disabled'),
        contentPadding: const EdgeInsets.all(0),
        title: Text(title),
        trailing: Switch(
          value: deafultValue,
          onChanged: (bool value) => onChanged(value),
        ));
  }
}
