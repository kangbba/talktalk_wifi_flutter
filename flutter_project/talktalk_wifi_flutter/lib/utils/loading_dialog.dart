import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

loadingDialog(BuildContext context, String message) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 외부 터치로 닫히지 않도록 설정
    builder: (BuildContext context) {
      return PopScope(
        onPopInvokedWithResult: (popDisposition, result) async => false, // 뒤로 가기 버튼 무력화
        child: AlertDialog(
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
        ),
      );
    },
  );
}
