import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/forms/quiz_form.dart';
import 'package:lms_admin/components/custom_buttons.dart';
import 'package:lms_admin/components/dialogs.dart';
import 'package:lms_admin/models/question.dart';

class Questions extends ConsumerWidget {
  const Questions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionListProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Questions *', style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              style: IconButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Theme.of(context).primaryColor),
              onPressed: () {
                CustomDialogs.openResponsiveDialog(context, widget: const QuizForm(), verticalPaddingPercentage: 0.03);
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        questions.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('No questions found')),
              )
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, ref),
                itemCount: questions.length,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  final Question q = questions[index];
                  return ReorderableDragStartListener(
                    index: index,
                    key: Key(index.toString()),
                    child: ListTile(
                      title: Text('Q${index+1}. ${q.questionTitle}'),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.options.toString()),
                          const SizedBox(
                            height: 5,
                          ),
                          Text('Correct Answer: ${q.options[q.correctAnswerIndex]}'),
                        ],
                      ),
                      leading: const Icon(Icons.drag_handle),
                      trailing: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          CustomButtons.circleButton(
                            context,
                            icon: Icons.edit,
                            onPressed: () {
                              CustomDialogs.openResponsiveDialog(
                                context,
                                widget: QuizForm(question: q, questionIndex: index),
                                verticalPaddingPercentage: 0.03,
                              );
                            },
                          ),
                          CustomButtons.circleButton(
                            context,
                            icon: Icons.delete,
                            onPressed: () {
                              final questions = ref.read(questionListProvider);
                              questions.remove(q);
                              ref.read(questionListProvider.notifier).update((state) => [...questions]);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _onReorder(
    int oldIndex,
    int newIndex,
    WidgetRef ref,
  ) async {
    final List<Question> questions = ref.watch(questionListProvider);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final Question question = questions.removeAt(oldIndex);
    questions.insert(newIndex, question);
    ref.read(questionListProvider.notifier).update((state) => [...questions]);
  }
}
