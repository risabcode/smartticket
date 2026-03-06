import 'package:flutter/foundation.dart';

class SelectedAccountProvider extends ChangeNotifier {
  Map<String, dynamic>? _selectedAccount;

  Map<String, dynamic>? get selectedAccount => _selectedAccount;

  void setSelectedAccount(Map<String, dynamic>? account) {
    _selectedAccount = account;
    notifyListeners();
  }

  void clear() {
    _selectedAccount = null;
    notifyListeners();
  }
}
