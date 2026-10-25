import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

enum ServerState { checking, online, offline }

class ConnectionMonitor extends ChangeNotifier with WidgetsBindingObserver {
  final Api api;
  ServerState state = ServerState.checking;
  DateTime? checkedAt;
  Timer? _timer;
  bool _checking = false, _disposed = false;
  ConnectionMonitor(this.api) {
    WidgetsBinding.instance.addObserver(this);
    _start();
  }
  void _start() {
    _timer?.cancel();
    check();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => check());
  }

  Future<void> check() async {
    if (_checking || _disposed) return;
    _checking = true;
    try {
      final result = await http
          .get(Uri.parse('${api.base}/api/health'))
          .timeout(const Duration(seconds: 4));
      state = result.statusCode == 200
          ? ServerState.online
          : ServerState.offline;
    } catch (_) {
      state = ServerState.offline;
    }
    checkedAt = DateTime.now();
    _checking = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
