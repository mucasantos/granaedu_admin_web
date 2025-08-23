import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:youtube_parser/youtube_parser.dart';
import 'package:lms_admin/l10n/app_localizations.dart';

/*
  CURRENT ISSUES:
  1. Not maintained and slower
*/

class CustomHtmlEditor extends StatefulWidget {
  final HtmlEditorController controller;
  final String? initialText;
  final double height;
  final String hint;
  final String title;

  const CustomHtmlEditor({Key? key, required this.controller, this.initialText, required this.height, required this.hint, required this.title})
      : super(key: key);

  @override
  State<CustomHtmlEditor> createState() => _CustomHtmlEditorState();
}

class _CustomHtmlEditorState extends State<CustomHtmlEditor> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!kIsWeb) {
          widget.controller.clearFocus();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            height: widget.height,
            decoration: BoxDecoration(color: Colors.grey.shade200, border: Border.all(color: Colors.grey.shade300)),
            child: HtmlEditor(
              controller: widget.controller,
              htmlEditorOptions: HtmlEditorOptions(
                autoAdjustHeight: false,
                spellCheck: true,
                hint: widget.hint,
                shouldEnsureVisible: false,
                initialText: widget.initialText,
              ),
              htmlToolbarOptions: HtmlToolbarOptions(
                initiallyExpanded: false,
                defaultToolbarButtons: [
                  const OtherButtons(help: false, fullscreen: false, paste: false, copy: false),
                  const StyleButtons(),
                  const FontSettingButtons(fontName: false),
                  const FontButtons(subscript: false, superscript: false, clearAll: false),
                  const ListButtons(listStyles: false),
                  const ParagraphButtons(textDirection: false, decreaseIndent: false, increaseIndent: false),
                  const ColorButtons(),
                  const InsertButtons(
                    audio: false,
                    otherFile: false,
                    table: false,
                    video: false,
                    picture: false,
                  ),
                ],
                customToolbarInsertionIndices: [13],
                customToolbarButtons: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(0)),
                          child: const Icon(
                            LineIcons.image,
                            size: 25,
                          ),
                        ),
                        onTap: () => _openImageDialog(),
                      ),
                      InkWell(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(0)),
                          child: const Icon(
                            LineIcons.youtube,
                            size: 25,
                          ),
                        ),
                        onTap: () => _openYoutubeDialog(),
                      ),
                      InkWell(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(0)),
                          child: const Icon(
                            LineIcons.video,
                            size: 25,
                          ),
                        ),
                        onTap: () => _openNetworkVideoDialog(),
                      ),
                    ],
                  ),
                ],
                gridViewHorizontalSpacing: 0,
                videoExtensions: ['mp4'],
                renderBorder: true,
                toolbarPosition: ToolbarPosition.aboveEditor, //by default
                toolbarType: ToolbarType.nativeExpandable,
              ),
              otherOptions: const OtherOptions(height: 550),
              callbacks: Callbacks(onInit: () {
                widget.controller.setFullScreen();
              }),
            ),
          ),
        ],
      ),
    );
  }

  _openYoutubeDialog() {
    var youtubeCtlr = TextEditingController();
    var formKey = GlobalKey<FormState>();
    showDialog(
        context: context,
        builder: ((context) {
          return PointerInterceptor(
            child: AlertDialog(
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context).commonCancel)),
                TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      String? videoId = getIdFromUrl(youtubeCtlr.text);
                      widget.controller.insertHtml(
                          '''<iframe width="560" height="315" src="https://www.youtube.com/embed/$videoId" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen=""></iframe><br>''');
                      Navigator.pop(context);
                    }
                  },
                  child: Text(AppLocalizations.of(context).commonAdd),
                ),
              ],
              title: Text(AppLocalizations.of(context).editorYoutubeUrlTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: youtubeCtlr,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).editorEnterYoutubeUrlHint,
                        label: Text(AppLocalizations.of(context).editorUrlLabel),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => youtubeCtlr.clear(),
                        ),
                      ),
                      validator: ((value) {
                        if (value!.isEmpty) return AppLocalizations.of(context).validationValueEmpty;
                        String? videoId = getIdFromUrl(youtubeCtlr.text);
                        if (videoId == null) return AppLocalizations.of(context).validationInvalidVideoId;
                        return null;
                      }),
                    ),
                  )
                ],
              ),
            ),
          );
        }));
  }

  _openImageDialog() {
    var imageCtlr = TextEditingController();
    var formKey = GlobalKey<FormState>();
    showDialog(
        context: context,
        builder: ((context) {
          return PointerInterceptor(
            child: AlertDialog(
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context).commonCancel)),
                TextButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        widget.controller.insertHtml('''<img src="${imageCtlr.text}" alt=""><br>''');
                        Navigator.pop(context);
                      }
                    },
                    child: Text(AppLocalizations.of(context).commonAdd)),
              ],
              title: Text(AppLocalizations.of(context).editorImageUrlTitle),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: imageCtlr,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).editorEnterImageUrlHint,
                        label: Text(AppLocalizations.of(context).editorUrlLabel),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => imageCtlr.clear(),
                        ),
                      ),
                      validator: ((value) {
                        if (value!.isEmpty) return AppLocalizations.of(context).validationValueEmpty;
                        bool validURL = Uri.parse(value).isAbsolute;
                        if (!validURL) return AppLocalizations.of(context).validationInvalidUrl;
                        return null;
                      }),
                    )
                  ],
                ),
              ),
            ),
          );
        }));
  }

  _openNetworkVideoDialog() {
    var videoCtlr = TextEditingController();
    var formKey = GlobalKey<FormState>();
    showDialog(
        context: context,
        builder: ((context) {
          return PointerInterceptor(
            child: AlertDialog(
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context).commonCancel)),
                TextButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        widget.controller.insertHtml('''<video width="560" height="315" controls="" src="${videoCtlr.text}"></video><br>''');
                        Navigator.pop(context);
                      }
                    },
                    child: Text(AppLocalizations.of(context).commonAdd)),
              ],
              title: Text(AppLocalizations.of(context).editorNetworkVideoUrlTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: formKey,
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).editorEnterVideoUrlHint,
                        label: Text(AppLocalizations.of(context).editorUrlLabel),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => videoCtlr.clear(),
                        ),
                      ),
                      controller: videoCtlr,
                      validator: ((value) {
                        if (value!.isEmpty) return AppLocalizations.of(context).validationValueEmpty;
                        bool validURL = Uri.parse(value).isAbsolute;
                        if (!validURL) return AppLocalizations.of(context).validationInvalidUrl;
                        return null;
                      }),
                    ),
                  )
                ],
              ),
            ),
          );
        }));
  }
}
