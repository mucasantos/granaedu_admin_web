import 'package:flutter/material.dart';
import 'package:lms_admin/configs/assets_config.dart';

class EmptyPageWithImage extends StatelessWidget {
  const EmptyPageWithImage({Key? key, required this.title, this.message, this.image}) : super(key: key);

  final String title;
  final String? message, image;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              image ?? AssetsConfig.noDataImage,
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Visibility(
                visible: message != null,
                child: Text(
                  message.toString(),
                  textAlign: TextAlign.center,
                ))
          ],
        ),
      ),
    );
  }
}
