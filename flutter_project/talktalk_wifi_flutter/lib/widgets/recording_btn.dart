import 'package:flutter/material.dart';

class RecordingBtn extends StatefulWidget {

  final VoidCallback onPressed;
  final Color? backgroundColor, btnColor;
  const RecordingBtn({
    required this.onPressed,
    required this.backgroundColor,
    required this.btnColor,
    super.key,
  });

  @override
  State<RecordingBtn> createState() => _RecordingBtnState();
}
class _RecordingBtnState extends State<RecordingBtn> {
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return recordBtn();
  }

  Widget recordBtn() {
    return InkWell(
      onTap: () {
        widget.onPressed(); // 버튼 클릭 시 실행될 함수
      },
      child: Container(
        width: 40, // 버튼의 크기 설정
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle, // 버튼을 원형으로 설정
          color: widget.backgroundColor, // 배경색 투명으로 설정
        ),
        child: Icon(
          Icons.mic,
          color: widget.btnColor, // 아이콘 색상 설정
          size: 40,
        ),
      ),
    );
  }
}
