import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/radio_options.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/mixins/textfields.dart';
import 'package:lms_admin/models/question.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../components/custom_buttons.dart';

const Map<String, String> quizOptionTypes = {'four': 'Four Options', 'two': 'Two Options'};
final questionListProvider = StateProvider<List<Question>>((ref) => []);

class QuizForm extends ConsumerStatefulWidget {
  const QuizForm({Key? key, this.question, this.questionIndex}) : super(key: key);

  final Question? question;
  final int? questionIndex;

  @override
  ConsumerState<QuizForm> createState() => _SectionFormState();
}

class _SectionFormState extends ConsumerState<QuizForm> with TextFields {
  var formKey = GlobalKey<FormState>();
  var questionTitleCtlr = TextEditingController();
  var option1Ctlr = TextEditingController();
  var option2Ctlr = TextEditingController();
  var option3Ctlr = TextEditingController();
  var option4Ctlr = TextEditingController();
  final btnCtlr = RoundedLoadingButtonController();
  int? _correctAnswerIndex;
  String _optionType = quizOptionTypes.entries.first.key;

  List _getOptions() {
    if (_optionType == quizOptionTypes.keys.first) {
      return [option1Ctlr.text, option2Ctlr.text, option3Ctlr.text, option4Ctlr.text];
    } else {
      return [option1Ctlr.text, option2Ctlr.text];
    }
  }

  _handleSubmit() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      final Question question = Question(
        questionTitle: questionTitleCtlr.text,
        options: _getOptions(),
        correctAnswerIndex: _correctAnswerIndex!,
      );

      final questions = ref.read(questionListProvider);

      if (widget.question == null) {
        questions.add(question);
      } else {
        questions[widget.questionIndex!] = question;
      }

      ref.read(questionListProvider.notifier).update((state) => [...questions]);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      questionTitleCtlr.text = widget.question!.questionTitle;
      _correctAnswerIndex = widget.question!.correctAnswerIndex;
      option1Ctlr.text = widget.question!.options[0];
      option2Ctlr.text = widget.question!.options[1];
      if (widget.question!.options.length == 4) {
        option3Ctlr.text = widget.question!.options[2];
        option4Ctlr.text = widget.question!.options[3];
        _optionType = quizOptionTypes.keys.first;
      } else {
        _optionType = quizOptionTypes.keys.last;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomButtons.submitButton(
          context,
          width: 300,
          buttonController: btnCtlr,
          text: widget.question == null ? 'Add Question' : 'Update Question',
          onPressed: _handleSubmit,
        ),
      ),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextField(context, controller: questionTitleCtlr, hint: 'Enter Question Title', title: 'Question Title *'),
              const SizedBox(height: 30),
              RadioOptions(
                contentType: _optionType,
                options: quizOptionTypes,
                title: 'Options Type',
                icon: Icons.light,
                onChanged: (value) => setState(() => _optionType = value),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: buildTextField(context, controller: option1Ctlr, hint: '', title: 'Option A *'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildTextField(context, controller: option2Ctlr, hint: '', title: 'Option B *'),
                  )
                ],
              ),
              const SizedBox(height: 30),
              Visibility(
                visible: _optionType == quizOptionTypes.keys.first,
                child: Row(
                  children: [
                    Expanded(
                      child: buildTextField(context, controller: option3Ctlr, hint: '', title: 'Option C *'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildTextField(context, controller: option4Ctlr, hint: '', title: 'Option D *'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _correctAnswerDropdown(),
            ],
          ),
        ),
      ),
    );
  }

  Column _correctAnswerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Correct Answer',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          padding: const EdgeInsets.only(left: 15, right: 15),
          decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(0)),
          child: DropdownButtonFormField(
              decoration: const InputDecoration(border: InputBorder.none),
              validator: (value) {
                if (value == null) return 'Value is required';
                return null;
              },
              onChanged: (dynamic value) => setState(() => _correctAnswerIndex = value),
              initialValue: _correctAnswerIndex,
              hint: const Text('Select Correct Answer'),
              items: <DropdownMenuItem>[
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Option A'),
                ),
                const DropdownMenuItem(
                  value: 1,
                  child: Text('Option B'),
                ),
                DropdownMenuItem(
                  enabled: _optionType == quizOptionTypes.keys.first,
                  value: 2,
                  child: Text(
                    'Option C',
                    style: TextStyle(color: _optionType == quizOptionTypes.keys.first ? Colors.grey[900] : Colors.grey[200]),
                  ),
                ),
                DropdownMenuItem(
                  enabled: _optionType == quizOptionTypes.keys.first,
                  value: 3,
                  child: Text(
                    'Option D',
                    style: TextStyle(color: _optionType == quizOptionTypes.keys.first ? Colors.grey[900] : Colors.grey[200]),
                  ),
                )
              ]),
        ),
      ],
    );
  }
}
