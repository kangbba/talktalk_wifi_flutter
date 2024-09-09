import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Future<bool> loadingDialog(
    BuildContext context, String message, Future<void> Function() asyncTask) async {
  bool result = false;

  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Prevent closing the dialog by tapping outside
    builder: (BuildContext context) {
      // Start the async task after the dialog is built
      Future.microtask(() async {
        try {
          await asyncTask(); // Perform the async task
          Navigator.of(context).pop(true); // Return true if successful
        } catch (e) {
          Navigator.of(context).pop(false); // Return false if there's an error
        }
      });

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(vertical: 100),
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 20),
            LoadingAnimationWidget.inkDrop(
              size: 30,
              color: Colors.indigo,
            ),
          ],
        ),
      );
    },
  );

  return result; // Return the result of the async task
}
