import 'package:flutter/material.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/models/lesson.dart';
import 'package:lms_admin/models/question.dart';

class QuizPreview extends StatelessWidget {
  const QuizPreview({Key? key, required this.lesson}) : super(key: key);

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final questions = lesson.questions ?? [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: questions.length,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: Responsive.isMobile(context) ? 20 : 50),
        itemBuilder: (context, index) {
          final Question q = questions[index];
          return ListTile(
            title: Text('Q${index + 1}. ${q.questionTitle}'),
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
          );
        },
      ),
    );
  }
}
