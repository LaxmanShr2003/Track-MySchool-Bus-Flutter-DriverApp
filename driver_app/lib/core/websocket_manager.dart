import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketManager {
  WebSocketManager._internal();
  static final WebSocketManager instance = WebSocketManager._internal();

  IO.Socket? _socket;
  Completer<bool>? _connectionCompleter;
  bool _isConnecting = false;

  bool get isConnected => _socket?.connected == true;

  Future<bool> connect({String? token}) async {
    try {
      // If already connected, return true
      if (isConnected) return true;

      // If already connecting, wait for the existing connection
      if (_isConnecting && _connectionCompleter != null) {
        return await _connectionCompleter!.future;
      }

      // If there's a pending completer, complete it with false
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(false);
      }

      _isConnecting = true;
      _connectionCompleter = Completer<bool>();

      final String url =
          dotenv.env['WEB_SOCKET_API'] ?? 'ws://192.168.1.2:8080';

      print('🔌 Connecting to WebSocket: $url');

      _socket = IO.io(url, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        if (token != null) 'auth': {'token': token},
      });

      // Set up event listeners
      _socket!.once('connect', (_) {
        print('✅ WebSocket connected');
        if (_connectionCompleter != null &&
            !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(true);
        }
        _isConnecting = false;
      });

      _socket!.once('connect_error', (err) {
        print('❌ WebSocket connection error: $err');
        if (_connectionCompleter != null &&
            !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        _isConnecting = false;
      });

      _socket!.once('error', (err) {
        print('❌ WebSocket error: $err');
        if (_connectionCompleter != null &&
            !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        _isConnecting = false;
      });

      _socket!.once('disconnect', (_) {
        print('🔌 WebSocket disconnected');
        _isConnecting = false;
      });

      // Connect to the server
      _socket!.connect();

      // Wait for connection with timeout
      final ok = await _connectionCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ WebSocket connection timeout');
          if (_connectionCompleter != null &&
              !_connectionCompleter!.isCompleted) {
            _connectionCompleter!.complete(false);
          }
          _isConnecting = false;
          return false;
        },
      );

      return ok;
    } catch (e) {
      print('❌ WebSocket connection exception: $e');
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(false);
      }
      _isConnecting = false;
      return false;
    }
  }

  void disconnect() {
    print('🔌 Disconnecting WebSocket');
    _isConnecting = false;

    // Complete any pending connection
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(false);
    }

    _socket?.disconnect();
    _socket = null;
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    if (isConnected) {
      print('📤 WebSocket emit: $event - $data');
      _socket?.emit(event, data);
    } else {
      print('❌ Cannot emit: WebSocket not connected');
    }
  }
}
