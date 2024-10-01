import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../secrets/secret_device_keys.dart';
import '../utils/utils.dart';

class BluetoothDeviceService {
  static StreamSubscription<List<ScanResult>>? scanSubscription;
  static bool _isScanning = false;
  static List<BluetoothDevice> scannedDevices = []; // 스캔된 장치 리스트를 저장하는 전역 변수

  static bool get isScanning => _isScanning;

  // Start scanning for BLE devices with a maximum duration
  static Future<BluetoothDevice?> startScan(String remoteID, int duration) async {
    if (_isScanning) {
      debugLog('이미 스캔이 진행 중입니다.');
      await stopScan();
    }

    _isScanning = true;
    scannedDevices.clear(); // 스캔을 시작할 때마다 리스트를 초기화
    debugLog('장치 스캔 시작 (최대 $duration초 동안 스캔 진행)');

    // 스캔 시작
    FlutterBluePlus.startScan();

    Completer<BluetoothDevice?> completer = Completer<BluetoothDevice?>();

    // 스캔 결과 처리
    scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) async {
      for (var result in results) {
        debugLog('장치 후보: ${result.device.advName}, remoteID: ${result.device.remoteId}');

        // Check if the found device matches the remoteID
        if (result.device.remoteId.toString() == remoteID) {
          debugLog('일치하는 장치 발견: ${result.device.remoteId}');

          // 장치를 반환하고 스캔을 중단
          await stopScan();
          completer.complete(result.device);
          return;
        }
      }
    });

    // 스캔을 일정 시간 동안만 수행
    Future.delayed(Duration(seconds: duration), () async {
      if (!_isScanning) return; // 이미 스캔이 중지된 경우 리턴

      debugLog('$duration초 동안 조건에 맞는 장치를 찾지 못했습니다.');
      await stopScan();
      completer.complete(null); // 시간 초과 시 null 반환
    });

    return completer.future;
  }

  // Remote ID를 로컬에 저장
  static Future<void> saveRemoteId(String remoteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedRemoteId', remoteId);
    debugLog('Remote ID $remoteId가 로컬에 저장되었습니다.');
  }

  // 로컬에서 저장된 Remote ID 가져오기
  static Future<String?> getSavedRemoteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('savedRemoteId');
  }

  // 저장된 Remote ID 삭제
  static Future<void> clearSavedRemoteId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedRemoteId');
    debugLog('저장된 Remote ID가 삭제되었습니다.');
  }

  // Stop scanning (without disconnecting)
  static Future<void> stopScan() async {
    if (!_isScanning) {
      debugLog('중지할 스캔이 없습니다.');
      return;
    }

    _isScanning = false;
    if (scanSubscription != null) {
      await scanSubscription!.cancel();
      scanSubscription = null;
      FlutterBluePlus.stopScan();
      debugLog('BLE 스캔 중지');
    }
  }

  // 로컬에 저장된 Remote ID로부터 BluetoothDevice를 생성하여 반환
  static Future<BluetoothDevice?> getBondedDevice() async {
    // 로컬에 저장된 Remote ID 가져오기
    String? savedRemoteId = await getSavedRemoteId();

    if (savedRemoteId != null) {
      // 저장된 Remote ID로 BluetoothDevice 생성
      BluetoothDevice device = BluetoothDevice.fromId(savedRemoteId);
      debugLog('저장된 Remote ID로부터 장치 생성: $savedRemoteId');
      return device;
    } else {
      debugLog('저장된 Remote ID가 없습니다.');
      return null;
    }
  }

  // 장치 연결 메소드
  static Future<void> connectToDevice(BluetoothDevice device, int durationMilliSec) async {
    debugLog('${device.advName}에 연결 시도 중...');
    try {
      await device.connect(mtu : null, autoConnect : true, timeout: Duration(milliseconds: durationMilliSec));
      debugLog('${device.advName}에 성공적으로 연결됨');
      // 연결 성공 시 remoteId 저장
      await saveRemoteId(device.remoteId.toString());
    } catch (e) {
      debugLog('연결 실패: $e');
    }
  }
  // Remote ID로 직접 장치에 연결하는 메서드
  static Future<void> connectToDeviceById(String remoteId, int durationMilliSec) async {
    try {
      // Remote ID를 사용하여 BluetoothDevice 객체 생성
      BluetoothDevice device = BluetoothDevice.fromId(remoteId);
      debugLog('Remote ID $remoteId의 장치에 연결 시도 중...');

      // 장치에 연결 시도
      await device.connect(mtu : null, autoConnect : true, timeout: Duration(milliseconds: durationMilliSec));
      debugLog('Remote ID $remoteId의 장치에 성공적으로 연결됨');
      // 연결 성공 시 remoteId 저장
      await saveRemoteId(remoteId);
      await device.requestMtu(512);
    } catch (e) {
      debugLog('Remote ID $remoteId의 장치 연결 실패: $e');
    }
  }


  // 장치 연결 해제 메소드
  static Future<void> disconnectCurrentDevice(BluetoothDevice bleDevice) async {
    debugLog('${bleDevice.advName} 연결해제 시도 중...');
    try {
      await bleDevice.disconnect();
      debugLog('${bleDevice.advName} 연결 해제 성공');
    } catch (e) {
      debugLog('연결 해제 실패: $e');
    }
  }

  static BluetoothDevice getBleDevice(String remoteID){
    BluetoothDevice device = BluetoothDevice.fromId(remoteID);
    return device;
  }


  // Write a message to the connected device
  static Future<void> writeMsgToCurrentBleDevice(String targetDeviceRemoteID, String msg) async {


    BluetoothDevice? bleDevice;
    // debugLog("우선 Bonded 검사");
    // bleDevice = await BluetoothDeviceService.getBondedDevice();
    // if (bleDevice == null) {
    //   debugLog("우선 Bonded 없었다");
    //   bleDevice = await BluetoothDeviceService.startScan(targetDeviceRemoteID);
    // }
    // else{
    //   debugLog("우선 Bonded 있었다 ${bleDevice.remoteId}");
    // }
    bleDevice = await BluetoothDeviceService.getBondedDevice();
    if(bleDevice != null){
      debugLog("BONDED DEVICE EXIST : ${bleDevice.remoteId} ${bleDevice.advName} ${bleDevice.platformName}");
      await connectToDeviceById(targetDeviceRemoteID, 2000);
    }

    if(bleDevice == null){
      bleDevice = await BluetoothDeviceService.startScan(targetDeviceRemoteID, 2);
      if(bleDevice == null){
        debugLog('장치가 없습니다.');
        return;
      }
      await connectToDeviceById(targetDeviceRemoteID, 2000);
    }
    BluetoothConnectionState connectionState = await bleDevice.connectionState.first;
    if (connectionState != BluetoothConnectionState.connected) {
      debugLog('장치가 연결되지 않았습니다. 현재 상태: $connectionState');
      return;
    }

    debugLog('장치가 연결된 상태. 메시지 전송을 시도합니다.');
    debugLog('${bleDevice.advName}, ${bleDevice.remoteId}로 메시지 전송 시도 중');
    try {
      List<BluetoothService> services = await bleDevice.discoverServices();
      debugLog('발견된 서비스: ${services.length}');

      var targetService = services.firstWhere(
            (service) => service.uuid == SERVICE_UUID,
        orElse: () => throw Exception('서비스를 찾을 수 없습니다.'),
      );

      var targetCharacteristic = targetService.characteristics.firstWhere(
            (characteristic) => characteristic.uuid == CHARACTERISTIC_UUID_RX,
        orElse: () => throw Exception('RX 특성을 찾을 수 없습니다.'),
      );

      await targetCharacteristic.write(utf8.encode(msg), withoutResponse: false);
      debugLog('${bleDevice.advName}, ${bleDevice.remoteId}로 메시지 ${msg} 전송 성공');
    } catch (e) {
      debugLog('메시지 전송 실패: $e');
    }
  }
}
