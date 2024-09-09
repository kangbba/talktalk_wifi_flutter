// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:speech_to_text/speech_recognition_result.dart';
// import 'package:speech_to_text/speech_recognition_error.dart';
// import '../utils/utils.dart';
//
// class SpeechToTextControl extends ChangeNotifier {
//   late SpeechToText _speech; // Initialize SpeechToText instance
//   bool _isCompleted = false;
//   String _transcription = '';
//   String _langCode = '';
//
//   bool get isCompleted => _isCompleted;
//   set isCompleted(bool value) {
//     _isCompleted = value;
//     notifyListeners();
//   }
//
//   String get transcription => _transcription;
//   set transcription(String value) {
//     _transcription = value;
//     notifyListeners();
//   }
//
//   void activateSpeechRecognizer() {
//     isCompleted = false;
//     debugLog('Activating Speech Recognition...');
//     _speech = SpeechToText();
//     // _speech.initialize(
//     //   onStatus: onRecognitionStatus,
//     //   onError: onError,
//     //   debugLogging: true,
//     // );
//   }
//
//   void start(String langCode) async {
//     isCompleted = false;
//     _langCode = langCode;
//     bool available = await _speech.initialize(
//       onStatus: onRecognitionStatus,
//       onError: onError,
//     );
//
//     if (available) {
//       _speech.listen(
//         onResult: resultListener,
//         localeId: _langCode,
//         listenFor: const Duration(seconds: 30), // Optional: specify listening time
//         pauseFor: const Duration(seconds: 2),  // Optional: specify pause time
//         listenOptions: SpeechListenOptions(listenMode : ListenMode.dictation, partialResults: true),
//
//       );
//     }
//   }
//
//   void stop() async {
//     await _speech.stop();
//     isCompleted = true;
//   }
//
//   void cancel() async {
//     await _speech.cancel();
//   }
//
//   void onRecognitionStatus(String status) {
//     debugLog('Recognition status: $status');
//   }
//
//   void resultListener(SpeechRecognitionResult result) {
//     debugLog('Recognition result: ${result.recognizedWords}');
//     transcription = result.recognizedWords;
//     isCompleted = result.finalResult;
//   }
//
//   void onError(SpeechRecognitionError error) {
//     debugLog('Recognition error: ${error.errorMsg}');
//   }
// }
