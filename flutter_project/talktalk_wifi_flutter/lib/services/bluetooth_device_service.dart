import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

import '../utils/utils.dart';
import '../secrets/secret_device_keys.dart';

class BluetoothDeviceService {
  // 알림 리스너를 관리하기 위한 변수


  StreamSubscription<List<int>>? notificationSubscription;
  bool isActionExecuting = false; // 액션이 실행 중인지 확인하는 플래그
  Timer? actionCooldownTimer; // 액션의 연속 실행을 방지하기 위한 타이머

  // TX 캐릭터리스틱의 알림을 감지하고 /askMic 메시지를 처리

  // TX 캐릭터리스틱의 알림을 감지하고 /askMic 메시지를 처리
  bool isHandlerStarted = false;
  Future<void> registerNotification(
    BluetoothCharacteristic characteristic, Function() action) async {
    if(notificationSubscription != null){
      debugLog('Notification already started: ${characteristic.uuid}');
       return;
    }
    try {
      // 기존의 알림 구독이 있을 경우 해제(dispose)
      // 알림 활성화
      await characteristic.setNotifyValue(true);
      debugLog('Notification enabled on characteristic: ${characteristic.uuid}');

      // 일반 스트림으로 값 변경 감지
      notificationSubscription = characteristic.onValueReceived.listen((value) async {
        String receivedData = utf8.decode(value);
        debugLog('받은 데이터: $receivedData');

        // "/askMic" 메시지를 감지
        if (receivedData == "/askMic") {
          debugLog('"/askMic" 메시지 감지됨');

          // 액션이 실행 중이 아니고, 타이머가 작동 중이지 않을 때만 실행
          if (!isActionExecuting && (actionCooldownTimer == null || !actionCooldownTimer!.isActive)) {
            isActionExecuting = true; // 실행 상태로 변경
            action();

            // 타이머 시작: 설정된 시간 동안 추가 실행 방지
            actionCooldownTimer = Timer(const Duration(seconds: 2), () {
              isActionExecuting = false; // 실행 상태 해제
            });
          } else {
            debugLog('액션이 이미 실행 중이거나, 쿨다운 중입니다. 중복 실행 방지.');
          }
        } else if (receivedData == "/askMicReset") {
          // Reset 메시지를 감지하면 상태 해제
          debugLog('"/askMicReset" 메시지 감지됨');
          isActionExecuting = false;
          actionCooldownTimer?.cancel(); // 타이머도 초기화하여 다음 실행을 허용
        }
      });

      debugLog('알림 리스너 등록 완료');
    } catch (e) {
      debugLog('알림 등록 실패: $e');
    }
  }


  static Future<BluetoothDevice?> scanPreConnectedBleDevice(String productName) async {
    // SharedPreferences에서 최근에 저장된 기기 이름 가져오기
    final prefs = await SharedPreferences.getInstance();
    String? recentDeviceName = prefs.getString('recentDevice'); // 최근 연결된 기기 이름을 shared data에서 불러옴


    // Connected Devices 검색
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    debugLog('Connected Devices: ${connectedDevices.length}');
    if (connectedDevices.isNotEmpty) {
      // 첫 번째 connected device를 연결
      BluetoothDevice device = connectedDevices.first;
      debugLog('Connected Device 연결: ${device.advName}');
      return device;
    }
    // Bonded Devices 검색
    List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices;
    debugLog('Bonded Devices: ${bondedDevices.length}');
    if (bondedDevices.isNotEmpty) {
      // 첫 번째 bonded device를 연결
      BluetoothDevice device = bondedDevices.first;
      debugLog('Bonded Device 연결: ${device.advName}');
      return device;
    }

    // 일치하는 디바이스를 찾지 못했을 경우
    debugLog('일치하는 기기를 찾지 못했습니다.');
    return null;
  }




  static Future<ScanResult?> scanNearBleDevicesByProductName(String productName, int timeoutSeconds) async {
    Completer<ScanResult?> completer = Completer<ScanResult?>();
    StreamSubscription? scanSubscription;

    // 스캔 시작
    FlutterBluePlus.startScan(timeout: Duration(seconds: timeoutSeconds));
    debugLog('Finding BLE Device Name: $productName');

    // 스캔 결과 수신 및 조건 검사
    scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      debugLog('Scan results received: ${results.length}');
      for (var result in results) {
        // 디바이스의 advName이 주어진 productName과 정확히 일치하는지 확인
        debugLog('Found BLE Device Name : ${result.device.advName}');
        if (result.device.advName == productName) {
          debugLog('Found matching device: ${result.device.advName}');
          if (!completer.isCompleted) {
            completer.complete(result);  // 첫 번째 일치하는 디바이스를 찾으면 완료
          }
          break;
        }
      }
    });

    // 지정된 시간 동안 디바이스를 찾지 못하면 null 반환
    Future.delayed(Duration(seconds: timeoutSeconds)).then((_) {
      if (!completer.isCompleted) {
        debugLog('Timeout: No device matched the specified name within the given time.');
        completer.complete(null);
      }
    });

    // 스캔 완료 후 구독 해제 및 스캔 중지
    completer.future.then((_) async {
      await scanSubscription?.cancel();
      FlutterBluePlus.stopScan();
      debugLog('Scan stopped and subscription cancelled.');
    });

    return completer.future;
  }

  static Future<void> writeMsgToBleDevice(BluetoothDevice? bluetoothDevice, String msg) async {
    if (bluetoothDevice == null) {
      debugLog("writeMsgToBleDevice :: device is null");
      return;
    }
    debugLog('Attempting to send message to ${bluetoothDevice.advName}, ${bluetoothDevice.remoteId}');
    if (!bluetoothDevice.isConnected) {
      await bluetoothDevice.connect();
      debugLog('Connection attempt to ${bluetoothDevice.advName}, ${bluetoothDevice.remoteId} completed.');
    }
    try {
      // 연결된 기기를 찾고, 쓰기 특성에 메세지를 씁니다.
      List<BluetoothService> services = await bluetoothDevice.discoverServices();
      debugLog('Discovered ${services.length} services');
      for (var service in services) {
        debugLog('Found service: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          debugLog('  Characteristic: ${characteristic.uuid}');
        }
      }
      var targetService = services.firstWhere(
            (service) => service.uuid == SERVICE_UUID,
        orElse: () => throw Exception('Service not found'),
      );
      var targetCharacteristic = targetService.characteristics.firstWhere(
            (characteristic) => characteristic.uuid == CHARACTERISTIC_UUID_RX,
        orElse: () => throw Exception('RX Characteristic not found'),
      );

      await targetCharacteristic.write(utf8.encode(msg), withoutResponse: false, allowLongWrite: false);
      debugLog('Message sent successfully.');
    } catch (e) {
      debugLog('Write failed due to: $e');
    }
  }

  static Future<void> connectToDevice(BluetoothDevice? bluetoothDevice) async {
    if (bluetoothDevice == null) {
      debugLog("connectToDevice :: device is null");
      return;
    }
    try {
      await bluetoothDevice.connect();
      debugLog("Connected to device: ${bluetoothDevice.platformName}");
    } catch (e) {
      debugLog('Failed to connect to BLE device: $e');
    }
  }
  // 알림 리스너 해제 함수
  Future<void> unregisterNotification() async {
    try {
      await notificationSubscription?.cancel();
      notificationSubscription = null;
      debugLog('알림 리스너 해제됨');
    } catch (e) {
      debugLog('알림 해제 실패: $e');
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    debugLog('스캔 중지됨.');
  }
}
