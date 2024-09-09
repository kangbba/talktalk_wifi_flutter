import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

import '../languages/language_control.dart';

class SpeechRecognitionPopUp extends StatefulWidget {
  final String titleText;
  final LanguageItem langItem;
  final double fontSize;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onCanceled;
  final VoidCallback? onCompleted;

  const SpeechRecognitionPopUp({
    Key? key,
    required this.titleText,
    required this.langItem,
    required this.fontSize,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.onCanceled,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<SpeechRecognitionPopUp> createState() => _SpeechRecognitionPopUpState();
}

class _SpeechRecognitionPopUpState extends State<SpeechRecognitionPopUp> {
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _textController = TextEditingController();
  bool _backBtnAvailable = false;
  Timer? _backBtnTimer;
  Timer? _noInputTimer;

  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognizer();
    _startBackBtnTimer();
    _startNoInputTimer();
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    _stopTimers();
    super.dispose();
  }

  void _initializeSpeechRecognizer() {
    _speech.initialize(
      onError: _handleError,
      onStatus: (status) => debugPrint('Speech Status: $status'),
    ).then((available) {
      if (available) {
        _startListening();
      } else {
        debugPrint('Speech recognition not available');
      }
    });
  }

  void _startListening() {
    _speech.listen(
      onResult: _handleResult,
      localeId: widget.langItem.speechLocaleId,
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      setState(() {
        _textController.text = result.recognizedWords;
      });
    }

    if (result.recognizedWords.length > 1000) {
      debugPrint("Too much length");
      _stopListening();
    }

    if (result.finalResult) {
      debugPrint(result.recognizedWords);
      _stopListening();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint("Speech recognition error: ${error.errorMsg}");
    _startListening(); // 에러 발생 시 음성 인식 재시작
  }

  void _stopListening() {
    _speech.stop();
    _completePopUp();
  }

  void _startBackBtnTimer() {
    _backBtnTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _backBtnAvailable = true;
      });
    });
  }

  void _startNoInputTimer() {
    _noInputTimer = Timer(const Duration(seconds: 10), () {
      _cancelPopUp();
    });
  }

  void _stopTimers() {
    _backBtnTimer?.cancel();
    _noInputTimer?.cancel();
  }

  void _cancelPopUp() {
    _stopTimers();
    _speech.stop();
    widget.onCanceled?.call();
    Navigator.pop(context);
  }

  void _completePopUp() {
    _stopTimers();
    _speech.stop();
    widget.onCompleted?.call();
    Navigator.pop(context, _textController.text);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_backBtnAvailable) {
          _cancelPopUp();
        }
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          children: [
            _buildBackButton(),
            _buildTitle(),
            _buildRippleAnimation(),
            _buildTextField(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      height: 30,
      child: Align(
        alignment: Alignment.topLeft,
        child: _backBtnAvailable
            ? InkWell(
          onTap: _cancelPopUp,
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black54,
            size: 32,
          ),
        )
            : Container(),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.titleText,
      style: const TextStyle(fontSize: 16, height: 1.1, color: Colors.black),
    );
  }

  Widget _buildRippleAnimation() {
    return Expanded(
      flex: 1,
      child: Center(
        child: RippleAnimation(
          color: widget.backgroundColor,
          delay: const Duration(milliseconds: 200),
          repeat: true,
          minRadius: 30,
          ripplesCount: 4,
          duration: const Duration(milliseconds: 1800),
          child: Icon(
            widget.icon,
            color: widget.iconColor,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: TextField(
          textAlign: TextAlign.center,
          decoration: const InputDecoration(border: InputBorder.none),
          readOnly: true,
          maxLines: 6,
          controller: _textController,
          style: TextStyle(fontSize: widget.fontSize, height: 1.25),
        ),
      ),
    );
  }
}
