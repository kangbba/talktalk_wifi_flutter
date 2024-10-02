import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
loadingDialog(BuildContext context, String message) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,  // 뒤로가기 및 외부 터치로 취소되지 않도록 설정
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
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

Future<void> showLoadingDialogWhileAsyncTask(BuildContext context, String message, Future<void> asyncTask) async {
  // 다이얼로그를 띄움
  showDialog(
    context: context,
    barrierDismissible: false,  // 외부 터치로 닫기 방지
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
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

  // 비동기 작업을 실행하고 완료될 때까지 대기
  await asyncTask;

  // 작업이 완료되면 다이얼로그 닫기
  Navigator.of(context).pop();
}
