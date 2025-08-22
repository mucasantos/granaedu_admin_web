// import 'package:flutter/material.dart';
// import 'package:line_icons/line_icons.dart';
// import 'package:pointer_interceptor/pointer_interceptor.dart';
// import 'package:quill_html_editor/quill_html_editor.dart';

// /*
//   CURRENT ISSUES:
//   1. Not properly maintaned
//   2. Cursor issue with multiple textfields
//   3. hintext and scrolbar is not shwoing
//   4. Loding issue on scroll
// */

// class CustomQuillHtmlEditor extends StatefulWidget {
//   CustomQuillHtmlEditor({Key? key, required this.controller, this.height, this.initialText}) : super(key: key);

//   final QuillEditorController controller;
//   final double? height;
//   final String? initialText;

//   @override
//   State<CustomQuillHtmlEditor> createState() => _CustomQuillHtmlEditorState();
// }

// class _CustomQuillHtmlEditorState extends State<CustomQuillHtmlEditor> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     widget.controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: widget.height ?? 500,
//       decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
//       child: Column(
//         children: [
//           ToolBar(
//             controller: widget.controller,
//             padding: const EdgeInsets.all(8),
//             iconSize: 20,
//             iconColor: Colors.grey.shade900,
//             activeIconColor: Colors.blue,
//             crossAxisAlignment: WrapCrossAlignment.start,
//             direction: Axis.horizontal,
//             toolBarColor: Colors.grey.shade100,
//             toolBarConfig: defaultToolbar,
//             customButtons: [
//               _linkButton(),
//               _imageButton(),
//               _videoButton(),
//               _clearButton(),
//             ],
//           ),
//           Expanded(
//             child: QuillHtmlEditor(
//               hintText: 'Enter Description',
//               hintTextStyle: TextStyle(fontSize: 16, color: Colors.grey),
//               controller: widget.controller,
//               text: widget.initialText,
//               isEnabled: true,
//               ensureVisible: false,
//               minHeight: widget.height ?? 500,
//               autoFocus: false,
//               textStyle: TextStyle(fontSize: 16),
//               hintTextAlign: TextAlign.start,
//               padding: const EdgeInsets.only(left: 10, top: 10),
//               hintTextPadding: const EdgeInsets.only(left: 20),
//               inputAction: InputAction.newline,
//               onEditingComplete: (s) => debugPrint('Editing completed $s'),
//               loadingBuilder: (context) {
//                 return const Center(
//                     child: CircularProgressIndicator(
//                   strokeWidth: 1,
//                   color: Colors.red,
//                 ));
//               },
//               onEditorCreated: (){
//                 widget.controller.unFocus();
//                 if(widget.initialText == null){
//                   widget.controller.clear();
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

  
//   // Default buttons
//   final List<ToolBarStyle> defaultToolbar = [
//     ToolBarStyle.undo,
//     ToolBarStyle.redo,
//     ToolBarStyle.bold,
//     ToolBarStyle.italic,
//     ToolBarStyle.underline,
//     ToolBarStyle.strike,
//     ToolBarStyle.headerOne,
//     ToolBarStyle.headerTwo,
//     ToolBarStyle.size,
//     ToolBarStyle.align,
//     ToolBarStyle.indentAdd,
//     ToolBarStyle.indentMinus,
//     ToolBarStyle.listOrdered,
//     ToolBarStyle.listBullet,
//     ToolBarStyle.background,
//     ToolBarStyle.color,
//     ToolBarStyle.blockQuote,
//     ToolBarStyle.directionLtr,
//     ToolBarStyle.directionRtl,
//   ];

//   InkWell _clearButton() {
//     return InkWell(
//       onTap: () => widget.controller.clear(),
//       child: Tooltip(
//         message: 'Clear All',
//         child: Icon(
//           Icons.clear,
//           size: 20,
//           color: Colors.grey.shade900,
//         ),
//       ),
//     );
//   }

//   InkWell _linkButton() {
//     return InkWell(
//       child: Tooltip(
//         message: 'Insert Link',
//         child: Icon(Icons.link, size: 20, color: Colors.grey.shade900),
//       ),
//       onTap: () async {
//         var linkTextCtlr = TextEditingController();
//         var titleTextCtlr = TextEditingController();
//         var formKey = GlobalKey<FormState>();

//         // Link for seleted text
//         final String selectedText = await widget.controller.getSelectedText();
//         if (selectedText.trim().isNotEmpty) {
//           titleTextCtlr.text = selectedText;
//         }
//         showDialog(
//             context: context,
//             builder: ((context) {
//               return PointerInterceptor(
//                 child: AlertDialog(
//                   actions: [
//                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                     TextButton(
//                       child: const Text('Add'),
//                       onPressed: () {
//                         if (formKey.currentState!.validate()) {
//                           formKey.currentState!.save();

//                           // Clearing the selected text and replace with html text
//                           if (selectedText.isNotEmpty) {
//                             widget.controller.replaceText('');
//                           }

//                           widget.controller.insertText('<a href="${linkTextCtlr.text}" target="_blank">${titleTextCtlr.text}</a>');
//                           Navigator.pop(context);
//                         } else {
//                           widget.controller.unFocus();
//                         }
//                       },
//                     ),
//                   ],
//                   title: const Text('Insert URL'),
//                   content: Form(
//                     key: formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextFormField(
//                           controller: titleTextCtlr,
//                           decoration: InputDecoration(
//                             hintText: 'Text to Display',
//                             label: const Text('Display Text'),
//                             suffixIcon: IconButton(
//                               icon: Icon(Icons.clear),
//                               onPressed: () => titleTextCtlr.clear(),
//                             ),
//                           ),
//                           validator: ((value) {
//                             if (value!.isEmpty) return 'Value is empty';
//                             return null;
//                           }),
//                         ),
//                         SizedBox(height: 10),
//                         TextFormField(
//                           controller: linkTextCtlr,
//                           decoration: InputDecoration(
//                             hintText: 'Enter URL',
//                             label: const Text('URL'),
//                             suffixIcon: IconButton(
//                               icon: Icon(Icons.clear),
//                               onPressed: () => linkTextCtlr.clear(),
//                             ),
//                           ),
//                           validator: ((value) {
//                             if (value!.isEmpty) return 'Value is empty';
//                             bool validURL = Uri.parse(value).isAbsolute;
//                             if (!validURL) return "Invalid URL";
//                             return null;
//                           }),
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }));
//       },
//     );
//   }

//   InkWell _imageButton() {
//     return InkWell(
//       child: Tooltip(
//         message: 'Insert Link',
//         child: Icon(LineIcons.image, size: 20, color: Colors.grey.shade900),
//       ),
//       onTap: () {
//         var imageTextCtlr = TextEditingController();
//         var formKey = GlobalKey<FormState>();
//         showDialog(
//             context: context,
//             builder: ((context) {
//               return PointerInterceptor(
//                 child: AlertDialog(
//                   actions: [
//                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                     TextButton(
//                       child: const Text('Add'),
//                       onPressed: () {
//                         if (formKey.currentState!.validate()) {
//                           formKey.currentState!.save();
//                           widget.controller..embedImage(imageTextCtlr.text);
//                           Navigator.pop(context);
//                         } else {
//                           widget.controller.unFocus();
//                         }
//                       },
//                     ),
//                   ],
//                   title: const Text('Insert Image URL'),
//                   content: Form(
//                     key: formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextFormField(
//                           controller: imageTextCtlr,
//                           decoration: InputDecoration(
//                             hintText: 'Enter Image URL',
//                             suffixIcon: IconButton(
//                               icon: Icon(Icons.clear),
//                               onPressed: () => imageTextCtlr.clear(),
//                             ),
//                           ),
//                           validator: ((value) {
//                             if (value!.isEmpty) return 'Value is empty';
//                             bool validURL = Uri.parse(value).isAbsolute;
//                             if (!validURL) return "Invalid URL";
//                             return null;
//                           }),
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }));
//       },
//     );
//   }

//   InkWell _videoButton() {
//     return InkWell(
//       child: Tooltip(
//         message: 'Insert Video Link',
//         child: Icon(LineIcons.youtube, size: 20, color: Colors.grey.shade900),
//       ),
//       onTap: () {
//         var videoTextCtlr = TextEditingController();
//         var formKey = GlobalKey<FormState>();
//         showDialog(
//             context: context,
//             builder: ((context) {
//               return PointerInterceptor(
//                 child: AlertDialog(
//                   actions: [
//                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                     TextButton(
//                       child: const Text('Add'),
//                       onPressed: () {
//                         if (formKey.currentState!.validate()) {
//                           formKey.currentState!.save();
//                           widget.controller..embedVideo(videoTextCtlr.text);
//                           Navigator.pop(context);
//                         } else {
//                           widget.controller.unFocus();
//                         }
//                       },
//                     ),
//                   ],
//                   title: const Text('Insert Video URL'),
//                   content: Form(
//                     key: formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextFormField(
//                           controller: videoTextCtlr,
//                           decoration: InputDecoration(
//                             hintText: 'Enter Video URL',
//                             suffixIcon: IconButton(
//                               icon: Icon(Icons.clear),
//                               onPressed: () => videoTextCtlr.clear(),
//                             ),
//                           ),
//                           validator: ((value) {
//                             if (value!.isEmpty) return 'Value is empty';
//                             bool validURL = Uri.parse(value).isAbsolute;
//                             if (!validURL) return "Invalid URL";
//                             return null;
//                           }),
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }));
//       },
//     );
//   }
// }
