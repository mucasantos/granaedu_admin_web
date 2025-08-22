import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';


void openTestingToast (context){
  return openFailureToast(context, 'Modification has been disabled in testing mode!');
}

void openToast(context, String message) {
  final toast = Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
    color: Theme.of(context).primaryColor,
    child: Text(
      message,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
    ),
  );
  FToast().init(context).showToast(child: toast);
}

void openFailureToast(context, String message) {
  final toast = Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
    color: Colors.red,
    child: Wrap(
      children: [
        const Icon(
          Icons.error,
          color: Colors.white,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          message,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
  FToast().init(context).showToast(child: toast);
}

void openSuccessToast(context, String message) {
  final toast = Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
    color: Theme.of(context).primaryColor,
    child: Wrap(
      children: [
        const Icon(
          Icons.done,
          color: Colors.white,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          message,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
  FToast().init(context).showToast(child: toast);
}
