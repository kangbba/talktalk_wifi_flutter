import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talktalk_wifi_flutter/utils/loading_dialog.dart';
import 'package:provider/provider.dart';
import '../secrets/secret_device_keys.dart';
import '../screens/speech_recognition_popup.dart';
import '../devices/audio_device_info.dart';
import '../languages/language_control.dart';
import '../languages/language_menu_selector.dart';
import '../languages/language_switcher.dart';
import '../services/audio_device_service.dart';
import '../services/bluetooth_device_service.dart';
import '../services/data_control.dart';
import '../services/permission_control.dart';
import '../services/text_to_speech_control.dart';
import '../services/translate_control.dart';
import '../utils/simple_confirm_dialog.dart';
import '../utils/menuconfig.dart';
import '../utils/utils.dart';
import '../widgets/recording_btn.dart';
import '../widgets/translation_area.dart';
import 'audio_test.dart';

enum ActingOwner{
  nobody,
  me,
  you,
}
class TranslatePageVoiceMode extends StatefulWidget {
  const TranslatePageVoiceMode({super.key});

  @override
  State<TranslatePageVoiceMode> createState() => _TranslatePageVoiceModeState();
}


ActingOwner nowActingOwner = ActingOwner.nobody;
bool isTesting = false;
DataControl dataControl = DataControl.getInstance();

const double micHeight = 30;


class _TranslatePageVoiceModeState extends State<TranslatePageVoiceMode> {


  DataControl dataControl = DataControl.getInstance();
  LanguageControl languageControl = LanguageControl.getInstance();
  TextToSpeechControl textToSpeechControl = TextToSpeechControl.getInstance();
  TranslateControl translateControl = TranslateControl.getInstance();
  final bool autoSwitchSpeaker = false;
  final bool isRoutingTest = false;
  int voiceTranslatingCounter = 0;
  bool isVoicePopUpOn = false;


  @override
  void initState() {
    super.initState();
    dataControl.initPrefs();
    debugLog("DataControl 설정 로드 완료");

    translateControl.initializeTranslateControl();
    debugLog("번역 관리 초기화 완료");

    languageControl.initLanguageControl('ko');
    textToSpeechControl.initTextToSpeech();
    debugLog("언어 설정 로드 및 언어 관리 초기화 완료");


  }

  @override
  void dispose() {
    nowActingOwner = ActingOwner.nobody;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LanguageControl>(
        builder: (context, languageControl, child) {
          return Column(
            children: [
              Container(
                height: 70,
                color : Colors.black12
              ),
              Expanded(
                child: TranslationArea(
                  textColor: (languageControl.myStr.isEmpty ? Colors.black45 : myBackgroundColor),
                  backgroundColor: Colors.white54,
                  str: (languageControl.myStr.isEmpty ? 'Tap the recording button' : languageControl.myStr),
                  isMine: true,
                ),
              ),
              Container(height: 0.6, color: Colors.grey,),
              Expanded(
                child: TranslationArea(
                  textColor: (languageControl.myStr.isEmpty ? Colors.black45 : Colors.black87),
                  backgroundColor: Colors.white54,
                  str: languageControl.yourStr,
                  isMine: false,
                ),
              ),
              Container(height: 0.6, color: Colors.grey,),
              SizedBox(
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: languageMenuAndRecordingBtn(context, languageControl, false),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: LanguageSwitcher(
                        backgroundColor: Colors.white54,
                        iconColor: Colors.black,
                        width: 50,
                        height: 50,
                        radius: 0,
                        iconSize: 26,
                        onTap: () {
                          languageControl.switchLanguagesEachOther();
                          languageControl.switchStrEachOther();
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      child: languageMenuAndRecordingBtn(context, languageControl, true),
                    ),
                  ],
                ),
              ),
              if(isRoutingTest)
                AudioTest().buildAudioControlRow(context, textToSpeechControl, languageControl),
            ],
          );
        },
      ),
    );
  }

  Future<int> getCurrentSdkInt() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }
  Widget languageMenuAndRecordingBtn(BuildContext context, LanguageControl languageControl, bool isMine) {
    return Column(
      children: [
        LanguageMenuSelector(
          width: 130,
          height: 60,
          isMyLanguage: isMine,
          textColor: Colors.black87,
          iconColor: Colors.black87,
          onTap: () async {
            languageControl.showLanguagesPairSelectScreen(context, isMine);
            setState(() {});
          },
        ),
        SizedBox(
          width: 70,
          height: 70,
          child: RecordingBtn(
            backgroundColor: isMine ? myBackgroundColor : yourBackgroundColor,
            btnColor: Colors.white,
            onPressed: () async {
              try{
                onPressedRecordingBtn(languageControl, isMine ? ActingOwner.me : ActingOwner.you);
              }
              catch(e){
                debugLog(e);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget audioDevicesList() {
    return Container(
      color: yourBackgroundColor,
      height: 32,
      child: FutureBuilder<List<AudioDevice>>(
        future: AudioDeviceService.getAllConnectedAudioDevices(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final devices = snapshot.data!;
            return ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.check_circle_outline_outlined, color: Colors.lightGreen,),
                      const SizedBox(width: 2),
                      Text(devices[index].name, style: TextStyle(color: Colors.indigo[50], fontSize: 14),),
                    ],
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Future<String> showVoicePopUp(ActingOwner btnOwner, BluetoothDevice? targetBleDevice) async {
    isVoicePopUpOn = true;
    LanguageItem fromLangItem = btnOwner == ActingOwner.me ? languageControl.nowMyLanguageItem : languageControl.nowYourLanguageItem;
    String speechStr = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: SizedBox(
            height: 500,
            child: SpeechRecognitionPopUp(
              icon: btnOwner == ActingOwner.me ? Icons.mic : Icons.pause,
              iconColor: Colors.white,
              backgroundColor: btnOwner == ActingOwner.me ? myBackgroundColor : yourBackgroundColor,
              langItem: fromLangItem, fontSize: 26,
              titleText: btnOwner == ActingOwner.me ? "Please speak now" : "Listening ...",
              onCompleted: () => onExitFromActingRoutine,
              onCanceled: () async {
                onExitFromActingRoutine();
                BluetoothDeviceService.writeMsgToBleDevice(targetBleDevice, "/mainScreenOn");
              }
            ),
          ),
        );
      },
    ) ?? '';
    isVoicePopUpOn = false;
    return speechStr;
  }


  Future<bool> allConditionCheck() async {
    bool permissionsReady = await PermissionControl.checkAndRequestPermissions();
    if (!permissionsReady) {
      onExitFromActingRoutine();
      if (mounted) {
        bool? resp = await askDialogColumn(context,
            const Text("Would you like to go to settings to allow permission?"
                "\n\n(Permission -> Mic, Bluetooth Permission)",
              style: TextStyle(fontSize: 16),), "OK", "CANCEL", 100);
        if (resp == true) {
          //세팅창 이동시켜줌
          openAppSettings();
        }
      }
      return false;
    }

    List<ConnectivityResult> result = await (Connectivity().checkConnectivity());

    if (result.first == ConnectivityResult.none) {
      // 네트워크 연결이 없는 경우 처리
      if (mounted) {
        simpleConfirmDialogA(context, 'Please check your network', "OK");
      }
      return false;
    }
    return true;
  }
  onPressedRecordingBtn(LanguageControl languageControl, ActingOwner btnOwner) async {
    //Presetting
    textToSpeechControl.stop();
    nowActingOwner = btnOwner;
    bool isMine = btnOwner == ActingOwner.me;
    bool isConditionReady = await allConditionCheck();
    if (!isConditionReady) {
      onExitFromActingRoutine();
      return;
    }
    List<AudioDevice> allConnectedAudioDevices = await AudioDeviceService.getConnectedAudioDevicesByPrefixAndType(PRODUCT_PREFIX, 7);
    if (allConnectedAudioDevices.isEmpty) {
      onExitFromActingRoutine();
      if (mounted) {
        bool? resp = await askDialogColumn(context,
            const Text("Check Your Bluetooth Device",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),), "Go To Setting", "CANCEL", 100);
        if (resp == true) {
          //세팅창 이동시켜줌
          navigateToBluetoothSettings();
        }
      }
      return;
    }
    else if (allConnectedAudioDevices.length >= 2) {
      onExitFromActingRoutine();
      await simpleConfirmDialogA(context, "Multiple devices found, Please connect one device only", "OK");
      return;
    }
    //Finding valid ble device by HFP device name
    String targetDeviceName = allConnectedAudioDevices[0].name;

    BluetoothDevice? targetBleDevice;

    //Bonded 를 최우선으로 한다.
    BluetoothDevice? bondedDevice = await BluetoothDeviceService.getBondedDevice();
    targetBleDevice = bondedDevice;

    //Bonded가 없으면 주변에서 찾는다
    if(targetBleDevice == null){
      loadingDialog(context, "Searching for nearby devices");
      BluetoothDevice? nearDevice = await BluetoothDeviceService.getNearDevice(targetDeviceName, 2500);
      targetBleDevice = nearDevice;
      if(mounted){
        Navigator.pop(context);
      }
    }

    //그래도 없으면 작업을 수행하지않는다.
    if(targetBleDevice == null){
      await simpleConfirmDialogA(context, "No valid BLE Device", "OK");
      onExitFromActingRoutine();
      return;
    }

    //BLE 디바이스 연결 (targetBleDevice는 명백하게 존재한다)
    if(targetBleDevice.isDisconnected){
      loadingDialog(context, "Connecting to $targetDeviceName");
      await BluetoothDeviceService.connectToDeviceThenListen(targetBleDevice);
      if(mounted){
        Navigator.pop(context);
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    //말하기를 위한 라우팅 제어
    if (isMine) {
      debugLog("내 라우팅");
      AudioDeviceService.setAudioRouteMobile();
    }
    else {
      AudioDeviceService.setAudioRouteESPHFP(targetDeviceName);
      await BluetoothDeviceService.writeMsgToBleDevice(targetBleDevice, "/micScreenOn");
    }
    await Future.delayed(const Duration(milliseconds: 300));

    //음성인식 시작
    textToSpeechControl.changeLanguage(isMine ? languageControl.nowYourLanguageItem.speechLocaleId : languageControl.nowMyLanguageItem.speechLocaleId);
    String speechStr = await showVoicePopUp(btnOwner, targetBleDevice);

    //음성인식 완료 처리
    if (speechStr.isEmpty) {
      onExitFromActingRoutine();
      return;
    }
    if (isMine) {
      languageControl.myStr = speechStr;
    } else {
      languageControl.yourStr = speechStr;
    }
    setState(() {});

    //해석 수행
    bool succeed = await translateWithNowStatus(isMine);
    if (!succeed) {
      onExitFromActingRoutine();
      return;
    }
    setState(() {});


    if (isMine) {
      AudioDeviceService.setAudioRouteESPHFP(targetDeviceName);
    } else {
      AudioDeviceService.setAudioRouteMobile();
    }
    await Future.delayed(const Duration(milliseconds: 500));

    //BLE 디바이스로 전송
    String translatedStr = languageControl.yourStr.trim();
    List<int> msgBytes = utf8.encode(translatedStr);
    debugLog("*MSG DATA LENGTH : ${msgBytes.length}");
    List<int> truncatedBytes;
    if (msgBytes.length > 500) {
      truncatedBytes = msgBytes.sublist(0, 500);
    } else {
      truncatedBytes = msgBytes;
    }
    LanguageItem targetLanguageItem = languageControl.nowYourLanguageItem;
    String truncatedStr = utf8.decode(truncatedBytes);
    String fullMsgToSend = "${targetLanguageItem.uniqueId}:$truncatedStr;";
    await BluetoothDeviceService.writeMsgToBleDevice(targetBleDevice, fullMsgToSend);
    await Future.delayed(const Duration(milliseconds: 100));

    //perform text to speech
    String strToSpeech = isMine ? languageControl.yourStr : languageControl.myStr;
    LanguageItem toLangItem = isMine ? languageControl.nowYourLanguageItem : languageControl.nowMyLanguageItem;
    await textToSpeechControl.speakWithLanguage(strToSpeech.trim(), toLangItem.speechLocaleId);
    await Future.delayed(const Duration(milliseconds: 100));
    onExitFromActingRoutine();
    // 자동 전환 기능 추가
    if(autoSwitchSpeaker){
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          onPressedRecordingBtn(languageControl, btnOwner == ActingOwner.me ? ActingOwner.you : ActingOwner.me);
        }
      });
    }
  }
  Future<bool> translateWithNowStatus(bool isMine) async {
    String strToTranslate = isMine ? languageControl.myStr : languageControl.yourStr;
    LanguageItem fromLangItem = isMine ? languageControl.nowMyLanguageItem : languageControl.nowYourLanguageItem;
    LanguageItem toLangItem = isMine ? languageControl.nowYourLanguageItem : languageControl.nowMyLanguageItem;

    String translatedStr = await translateControl.translateByAvailablePlatform(strToTranslate, fromLangItem, toLangItem, 4000);
    if (translatedStr.isEmpty) {
      if (mounted) {
        simpleConfirmDialogA(context, 'The translation server is temporarily unstable. Please retry.', 'OK');
      }
      return false;
    }
    if (isMine) {
      languageControl.yourStr = translatedStr;
    } else {
      languageControl.myStr = translatedStr;
    }
    return true;
  }
  void onExitFromActingRoutine() async {
    nowActingOwner = ActingOwner.nobody;
    AudioDeviceService.setAudioRouteMobile();
  }

  Future<void> navigateToBluetoothSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.BLUETOOTH_SETTINGS',
    );
    await intent.launch();
  }

  // Future<void> registerMicAskListener(BluetoothDevice bleDevice) async{
  //   // 서비스와 캐릭터리스틱 검색
  //   List<BluetoothService> services = await bleDevice.discoverServices();
  //   var targetService = services.firstWhere(
  //         (service) => service.uuid == SERVICE_UUID,
  //     orElse: () => throw Exception('Service not found'),
  //   );
  //
  //   var txCharacteristic = targetService.characteristics.firstWhere(
  //         (characteristic) => characteristic.uuid == CHARACTERISTIC_UUID_TX,
  //     orElse: () => throw Exception('TX Characteristic not found'),
  //   );
  //
  //   // 알림 리스너 등록
  //   await BluetoothDeviceService().registerNotification(txCharacteristic, (){
  //     onExitFromActingRoutine();
  //     onPressedRecordingBtn(languageControl, ActingOwner.you);
  //   } );
  // }

}
