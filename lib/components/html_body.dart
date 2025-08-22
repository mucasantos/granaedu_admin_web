import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_admin/services/app_service.dart';

class HtmlBody extends StatelessWidget {
  final String content;
  final bool isVideoEnabled;
  final bool isimageEnabled;
  final bool isIframeVideoEnabled;
  final double? textPadding;
  const HtmlBody(
      {Key? key,
      required this.content,
      required this.isVideoEnabled,
      required this.isimageEnabled,
      required this.isIframeVideoEnabled,
      this.textPadding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Html(
      data: content,
      shrinkWrap: true,
      onLinkTap: (url, _, __) {
        AppService().openLink(context, url.toString());
      },
      style: {
        "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(17),
            lineHeight: const LineHeight(1.7),
            fontWeight: FontWeight.w400,
            color: Colors.black,
            fontFamily: 'Open Sans'),
        "p,h1,h2,h3,h4,h5,h6,br": Style(margin: Margins.zero, padding: HtmlPaddings.symmetric(vertical: 10)),
        "figure": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
      },
      extensions: [
        TagExtension(
          tagsToExtend: {"iframe"},
          builder: (ExtensionContext eContext) {
            final String source = eContext.attributes['src'].toString();
            if (isIframeVideoEnabled == false) return Container();
            if (source.contains('youtu')) {
              return _videoBox(context, source);
            }
            return Container();
          },
        ),
        TagExtension(
          tagsToExtend: {"video"},
          builder: (ExtensionContext eContext) {
            final String videoSource = eContext.attributes['src'].toString();
            if (isVideoEnabled == false) return Container();
            return _videoBox(context, videoSource);
          },
        ),
        TagExtension(
          tagsToExtend: {"img"},
          builder: (ExtensionContext eContext) {
            String imageUrl = eContext.attributes['src'].toString();
            if (isimageEnabled == false) return Container();
            return CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => const CircularProgressIndicator(),
            );
          },
        ),

        TagExtension(
          tagsToExtend: {"blockquote"},
          builder: (ExtensionContext eContext) {
            return IntrinsicHeight(
              child: Row(
                children: [
                  const VerticalDivider(),
                  Expanded(child: Text(eContext.element?.text ?? '')),
                ],
              ),
            );
            // String imageUrl = eContext.attributes['src'].toString();
            // if (isimageEnabled == false) return Container();
            // return CachedNetworkImage(
            //   imageUrl: imageUrl,
            //   placeholder: (context, url) => const CircularProgressIndicator(),
            // );
          },
        ),
      ],
    );
  }

  InkWell _videoBox(context, link) {
    return InkWell(
      onTap: () => AppService().openLink(context, link),
      child: Container(
        alignment: Alignment.center,
        color: Colors.grey.shade200,
        height: 300,
        width: 400,
        child: const Icon(LineIcons.video),
      ),
    );
  }
}
