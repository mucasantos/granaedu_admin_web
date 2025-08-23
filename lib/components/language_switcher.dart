import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/providers/locale_provider.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    void setLocale(Locale l) => ref.read(localeProvider.notifier).state = l;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangChip(
          label: 'PT',
          selected: current.languageCode == 'pt',
          onTap: () => setLocale(const Locale('pt')),
        ),
        const SizedBox(width: 8),
        _LangChip(
          label: 'EN',
          selected: current.languageCode == 'en',
          onTap: () => setLocale(const Locale('en')),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
