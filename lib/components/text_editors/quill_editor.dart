// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
// import 'package:line_icons/line_icons.dart';

// /*
//   CURRENT ISSUES:
//   1. Can't convert colors to html
//   2. Image & video sizes are not working properly

//   PROS:
//   1. Properly maintained
//   2. Fast, Fluent and popular
// */

// class CustomQuillEditor extends StatefulWidget {
//   CustomQuillEditor({Key? key, this.height, this.initialText, required this.controller, required this.title}) : super(key: key);

//   final double? height;
//   final String? initialText;
//   final QuillController controller;
//   final String title;

//   @override
//   State<CustomQuillEditor> createState() => _CustomQuillEditorState();
// }

// class _CustomQuillEditorState extends State<CustomQuillEditor> {
//   final ScrollController scrollController = ScrollController();

//   @override
//   void initState() {
//     if (widget.initialText != null) {
//       widget.controller.document = Document.fromJson(jsonDecode(widget.initialText ?? ''));
//     } else {}
//     super.initState();
//   }

//   final double customImageWidth = 300;
//   final double customImageHeight = 170;

//   void _addCustomImage(String imageUrl) {
//     final controller = widget.controller;
//     final delta = Delta.fromJson([
//       {'insert': '\n'},
//       {
//         'insert': {'image': imageUrl},
//         'attributes': {
//           'width': '$customImageWidth',
//           'height': '$customImageHeight',
//           'style': 'width:${customImageWidth}px; height:${customImageHeight}px;'
//         }
//       },
//       {'insert': '\n'},
//     ]);

//     controller.document.compose(delta, ChangeSource.local);

//     controller.updateSelection(
//       TextSelection.collapsed(
//         offset: controller.selection.extentOffset + 1,
//       ),
//       ChangeSource.local,
//     );

//     widget.controller.moveCursorToPosition(widget.controller.plainTextEditingValue.text.length);
//   }

//   void _addCustomVideo(String videoUrl) {
//     final controller = widget.controller;
//     final delta = Delta.fromJson([
//       {'insert': '\n'},
//       {
//         'insert': {'video': videoUrl},
//         'attributes': {
//           'width': '$customImageWidth',
//           'height': '$customImageHeight',
//           'style': 'width:${customImageWidth}px; height:${customImageHeight}px;'
//         }
//       },
//       {'insert': '\n'},
//     ]);

//     controller.document.compose(delta, ChangeSource.local);

//     controller.updateSelection(
//       TextSelection.collapsed(
//         offset: controller.selection.extentOffset + 1,
//       ),
//       ChangeSource.local,
//     );

//     widget.controller.moveCursorToPosition(widget.controller.plainTextEditingValue.text.length);
//   }

//   @override
//   void dispose() {
//     widget.controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             widget.title,
//             style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
//           ),
//           const SizedBox(height: 10),
//           Container(
//             height: widget.height ?? 500,
//             decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.grey.shade300)),
//             child: QuillProvider(
//               configurations: QuillConfigurations(
//                 controller: widget.controller,
//                 sharedConfigurations: const QuillSharedConfigurations(),
//               ),
//               child: Column(
//                 children: [
//                   QuillToolbar(
//                     configurations: QuillToolbarConfigurations(
//                         showSearchButton: false,
//                         showSubscript: false,
//                         showSuperscript: false,
//                         buttonOptions: const QuillToolbarButtonOptions(),
//                         embedButtons: FlutterQuillEmbeds.toolbarButtons(videoButtonOptions: null, imageButtonOptions: null),
//                         customButtons: [
//                           _imageButton(),
//                           _videoButton(),
//                         ]),
//                   ),
//                   const Divider(),
//                   Expanded(
//                     child: QuillEditor.basic(
//                       scrollController: scrollController,
//                       configurations: QuillEditorConfigurations(
//                         embedBuilders: FlutterQuillEmbeds.editorWebBuilders(
//                           imageEmbedConfigurations: QuillEditorWebImageEmbedConfigurations(
//                             constraints: BoxConstraints.loose(
//                               Size(customImageWidth, customImageHeight),
//                             ),
//                           ),
//                           videoEmbedConfigurations: QuillEditorWebVideoEmbedConfigurations(
//                             constraints: BoxConstraints.loose(
//                               Size(customImageWidth, customImageHeight),
//                             ),
//                           ),
//                         ),
//                         placeholder: 'Enter Description',
//                         expands: true,
//                         padding: const EdgeInsets.all(16),
//                         readOnly: false,
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   QuillToolbarCustomButtonOptions _imageButton() {
//     return QuillToolbarCustomButtonOptions(
//       icon: Icon(LineIcons.image, size: 20),
//       iconSize: 20,
//       tooltip: 'Image',
//       onPressed: () {
//         var imageCtlr = TextEditingController();
//         var formKey = GlobalKey<FormState>();
//         showDialog(
//             context: context,
//             builder: ((context) {
//               return AlertDialog(
//                 actions: [
//                   TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                   TextButton(
//                     child: const Text('Add'),
//                     onPressed: () {
//                       if (formKey.currentState!.validate()) {
//                         formKey.currentState!.save();
//                         // widget.controller.insertImageBlock(imageSource: imageCtlr.text);
//                         _addCustomImage(imageCtlr.text);
//                         Navigator.pop(context);
//                       }
//                     },
//                   ),
//                 ],
//                 title: const Text('Image URL'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Form(
//                       key: formKey,
//                       child: TextFormField(
//                         controller: imageCtlr,
//                         decoration: InputDecoration(
//                           hintText: 'Enter Image Url',
//                           suffixIcon: IconButton(
//                             icon: Icon(Icons.clear),
//                             onPressed: () => imageCtlr.clear(),
//                           ),
//                         ),
//                         validator: ((value) {
//                           if (value!.isEmpty) return 'Value is empty';
//                           bool validURL = Uri.parse(value).isAbsolute;
//                           if (!validURL) return "Invalid URL";
//                           return null;
//                         }),
//                       ),
//                     )
//                   ],
//                 ),
//               );
//             }));
//       },
//     );
//   }

//   QuillToolbarCustomButtonOptions _videoButton() {
//     return QuillToolbarCustomButtonOptions(
//       icon: Icon(LineIcons.youtube, size: 20),
//       tooltip: 'Video',
//       onPressed: () {
//         var videoTextCtlr = TextEditingController();
//         var formKey = GlobalKey<FormState>();
//         showDialog(
//             context: context,
//             builder: ((context) {
//               return AlertDialog(
//                 actions: [
//                   TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                   TextButton(
//                     child: const Text('Add'),
//                     onPressed: () {
//                       if (formKey.currentState!.validate()) {
//                         formKey.currentState!.save();
//                         // widget.controller.insertVideoBlock(videoUrl: videoTextCtlr.text);
//                         _addCustomVideo(videoTextCtlr.text);
//                         Navigator.pop(context);
//                       }
//                     },
//                   ),
//                 ],
//                 title: const Text('Video URL'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Form(
//                       key: formKey,
//                       child: TextFormField(
//                         controller: videoTextCtlr,
//                         decoration: InputDecoration(
//                           hintText: 'Enter Video URL',
//                           suffixIcon: IconButton(
//                             icon: Icon(Icons.clear),
//                             onPressed: () => videoTextCtlr.clear(),
//                           ),
//                         ),
//                         validator: ((value) {
//                           if (value!.isEmpty) return 'Value is empty';
//                           bool validURL = Uri.parse(value).isAbsolute;
//                           if (!validURL) return "Invalid URL";
//                           return null;
//                         }),
//                       ),
//                     )
//                   ],
//                 ),
//               );
//             }));
//       },
//     );
//   }
// }
