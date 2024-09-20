import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../secrets/secret_device_keys.dart';
import '../utils/utils.dart';
class BluetoothDeviceService {
  static BluetoothDevice? _connectedDevice; // 현재 연결된 장치
  static StreamSubscription<List<ScanResult>>? scanSubscription;
  static bool _isScanning = false;

  static bool get isScanning => _isScanning;

  // Start scanning for BLE devices and connect if found
  static Future<void> startScanAndConnect(String remoteID) async {
    // 먼저 페어링된 장치에서 remoteID와 일치하는 장치가 있는지 확인
    BluetoothDevice? bondedDevice = await getBondedDevice(remoteID);
    if (bondedDevice != null) {
      // 페어링된 장치가 있으면 스캔 없이 연결
      debugLog('페어링된 장치 발견: ${bondedDevice.remoteId}, 연결 시도 중');
      await connectToDevice(bondedDevice);
      return;
    }

    // 페어링된 장치가 없을 경우 스캔 시작
    if (_isScanning) {
      debugLog('이미 스캔이 진행 중입니다.');
      await stopScan();
    }

    _isScanning = true;
    debugLog('remoteID: $remoteID 장치 스캔 및 연결 시도 중');

    // 스캔 시작
    FlutterBluePlus.startScan();
    // 스캔 결과 처리
    scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) async {
      for (var result in results) {
        debugLog('장치 발견: ${result.device.advName}, remoteID: ${result.device.remoteId}');

        // Check if the found device matches the remoteID
        if (result.device.remoteId.toString() == remoteID) {
          debugLog('일치하는 장치 발견: ${result.device.remoteId}');
          await connectToDevice(result.device);
          break;
        }
      }
    });
  }

  // Bonded devices 중에서 remoteID로 검색
  static Future<BluetoothDevice?> getBondedDevice(String remoteID) async {
    List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices;
    for (var device in bondedDevices) {
      if (device.remoteId.toString() == remoteID) {
        return device;
      }
    }
    return null;
  }

  // Stop scanning and disconnect if connected
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

    // 연결된 장치가 있으면 연결 해제
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      debugLog('${_connectedDevice!.advName} 연결 해제됨');
      _connectedDevice = null;
    }
  }

  // 장치 연결 메소드
  static Future<void> connectToDevice(BluetoothDevice device) async {
    debugLog('${device.advName}에 연결 시도 중...');
    try {
      await device.connect();
      _connectedDevice = device; // 연결된 장치 저장
      debugLog('${device.advName}에 성공적으로 연결됨');
    } catch (e) {
      debugLog('연결 실패: $e');
    }
  }

  // Write a message to the connected device
  static Future<void> writeMsgToCurrentBleDevice(String msg) async {
    if (_connectedDevice == null) {
      debugLog('연결된 장치가 없습니다.');
      return;
    }

    debugLog('${_connectedDevice!.advName}, ${_connectedDevice!.remoteId}로 메시지 전송 시도 중');
    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
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
      debugLog('${_connectedDevice!.advName}, ${_connectedDevice!.remoteId}로 메시지 전송 성공');
    } catch (e) {
      debugLog('메시지 전송 실패: $e');
    }
  }
}

