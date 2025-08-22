import 'package:flutter/material.dart';
import 'package:lms_admin/components/html_body.dart';
import 'package:lms_admin/utils/reponsive.dart';
import 'package:lms_admin/models/lesson.dart';

class ArticlePreview extends StatelessWidget {
  const ArticlePreview({Key? key, required this.lesson}) : super(key: key);

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: HtmlBody(
          content: lesson.description.toString(),
          isVideoEnabled: true,
          isimageEnabled: true,
          isIframeVideoEnabled: true,
        ),
      ),
    );
  }
}
