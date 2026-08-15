import 'package:flutter/foundation.dart';

import '../models/telegram_proxy.dart';
import '../services/telegram_proxy_service.dart';

class TelegramProxyProvider extends ChangeNotifier {
  final TelegramProxyService _proxyService = TelegramProxyService();

  List<TelegramProxy> _proxies = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<TelegramProxy> get proxies => _proxies;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchProxies() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _proxies = await _proxyService.fetchProxies();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
