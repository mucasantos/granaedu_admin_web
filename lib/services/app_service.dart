import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lms_admin/utils/toasts.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: depend_on_referenced_packages
import 'package:html/parser.dart';

class AppService {
  static Future<XFile?> pickImage({double maxHeight = 600, double maxWidth = 10000}) async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery, maxHeight: maxHeight, maxWidth: maxWidth);
    return image;
  }

  static bool isURLValid(String url) {
    return Uri.parse(url).isAbsolute;
  }

  Future openLink(context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri);
    } else {
      openFailureToast(context, "Can't launch the URL");
    }
  }

  static String getDateTime(DateTime? dateTime) {
    var format = DateFormat('dd MMMM, yyyy hh:mm a');
    return format.format(dateTime ?? DateTime.now());
  }

  static String getDate(Timestamp timestamp) {
    var format = DateFormat('dd MMMM yy');
    return format.format(timestamp.toDate());
  }

  static String getNormalText(String text) {
    return HtmlUnescape().convert(parse(text).documentElement!.text);
  }
}
