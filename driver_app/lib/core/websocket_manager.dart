import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketManager {
  WebSocketManager._internal();
  static final WebSocketManager instance = WebSocketManager._internal();

  IO.Socket? _socket;
  Completer<bool>? _connectionCompleter;
  bool _isConnecting = false;

  // Store event listeners to emit events immediately if already connected
  final Map<String, List<Function(dynamic)>> _eventListeners = {};

  bool get isConnected => _socket?.connected == true;

  /// Check if WebSocket is healthy and can handle operations
  bool get isHealthy => isConnected && _socket != null;

  /// Handle server-side errors gracefully without disconnecting
  void handleServerError(dynamic error) {
    print('⚠️ WebSocket server error handled gracefully: $error');
    // Log the error but don't disconnect
    // This allows the connection to remain active for other operations
  }

  Future<bool> connect({String? token}) async {
    try {
      // If already connected, emit connect event and return true
      if (isConnected) {
        print('🔌 WebSocket already connected, emitting connect event');
        _emitEvent('connect', null);
        return true;
      }

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
          dotenv.env['WEB_SOCKET_API'] ?? 'ws://192.168.1.3:8080';

      print('🔌 Connecting to WebSocket: $url');

      _socket = IO.io(url, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        if (token != null) 'auth': {'token': token},
      });

      // Set up event listeners
      _socket!.once('connect', (_) {
        print('✅ WebSocket connected');
        _emitEvent('connect', null);
        if (_connectionCompleter != null &&
            !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(true);
        }
        _isConnecting = false;
      });

      _socket!.once('connect_error', (err) {
        print('❌ WebSocket connection error: $err');
        _emitEvent('connect_error', err);
        if (_connectionCompleter != null &&
            !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        _isConnecting = false;
      });

      _socket!.once('error', (err) {
        print('❌ WebSocket error: $err');
        _emitEvent('error', err);
        if (_connectionCompleter != null &&
            !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        _isConnecting = false;
      });

      // Add listener for server-side errors
      _socket!.on('error', (err) {
        print('❌ WebSocket server error: $err');
        _emitEvent('server_error', err);
        // Don't disconnect on server errors, just log them
      });

      // Add listener for custom error events from server
      _socket!.on('server_error', (err) {
        print('❌ WebSocket custom server error: $err');
        _emitEvent('server_error', err);
        // Don't disconnect on custom server errors, just log them
      });

      _socket!.once('disconnect', (_) {
        print('🔌 WebSocket disconnected');
        _emitEvent('disconnect', null);
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
    // Store the listener
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(handler);

    // If already connected and this is a connect event, emit immediately
    if (event == 'connect' && isConnected) {
      print('🔌 Emitting connect event immediately for new listener');
      handler(null);
    }

    // Also set up the socket listener
    _socket?.on(event, handler);
  }

  void off(String event) {
    // Remove from stored listeners
    if (_eventListeners.containsKey(event)) {
      _eventListeners[event]!.clear();
    }

    // Remove from socket
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    if (isConnected) {
      print('📤 WebSocket emit: $event - $data');
      try {
        _socket?.emit(event, data);
      } catch (e) {
        print('❌ Error emitting WebSocket event: $e');
        // Don't disconnect on emit errors, just log them
      }
    } else {
      print('❌ Cannot emit: WebSocket not connected');
    }
  }

  /// Emit event to all registered listeners
  void _emitEvent(String event, dynamic data) {
    if (_eventListeners.containsKey(event)) {
      for (final listener in _eventListeners[event]!) {
        try {
          listener(data);
        } catch (e) {
          print('❌ Error in event listener for $event: $e');
        }
      }
    }
  }

  /// Safely emit a message with error handling
  Future<bool> safeEmit(String event, dynamic data) async {
    if (!isHealthy) {
      print('❌ Cannot emit: WebSocket not healthy');
      return false;
    }

    try {
      print('📤 Safe WebSocket emit: $event - $data');
      _socket?.emit(event, data);
      return true;
    } catch (e) {
      print('❌ Error in safe emit: $e');
      handleServerError(e);
      return false;
    }
  }
}
