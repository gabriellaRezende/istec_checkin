
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/check_in.dart';

// AppState é a classe que gerencia o estado global da aplicação, incluindo o status de autenticação do usuário e o histórico de check-ins. Ela utiliza ChangeNotifier para notificar os widgets que dependem desses dados quando houver mudanças, permitindo uma atualização reativa da interface do usuário.
class AppState with ChangeNotifier {
  bool _isLoggedIn = false;
  List<CheckInRecord> _history = [];
  
  bool get isLoggedIn => _isLoggedIn;
  List<CheckInRecord> get history => _history;

  AppState() {
    _loadHistory(); // Carrega o histórico de check-ins do armazenamento local quando a aplicação é iniciada.
  }

  //Gerencia o processo de login. Apenas simula a autenticação e verifica se o campo de ID e senha estão vazios. 
  // Se estiver preenchido >> Login bem sucedido
  // Se estiver vazio >> Login falhou
  void login(String id, String pass) {
    if (id.isNotEmpty && pass.isNotEmpty) {
      _isLoggedIn = true;
      notifyListeners(); //Aqui vai notificar os widgets que dependem da resposta do login para atualizar a interface.
    }
  }

  //Gerencia o logout. Muda o estado de login para false e notifica os widgets para alterar a interface de volta para o login screen.
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  //Caso o novo registro de check-in for bem sucedido, ou seja, ele for válido, então adiciona na lista de hitórico e salva localmente.
  void addRecord(CheckInRecord record) {
    _history.insert(0, record);
    _saveHistory(); // Salva o histórico atualizado no armazenamento local.
    notifyListeners(); //Notifica os widgets para alterar o hitórico.
  }

  //Carrega o histórico do armazenamento local. 
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyData = prefs.getString('history');
      if (historyData != null && historyData.isNotEmpty) {
        final List decoded = jsonDecode(historyData);
        _history = decoded.map((item) => CheckInRecord.fromJson(item)).toList(); //Converte os dados locais para a lista de registos
        notifyListeners(); //Notifica o widget responsável para a tualizar a interface do histórico exatamente com os dados que estão salvos localmente.
      }
    } catch (e) {
      debugPrint('Erro ao carregar histórico: $e');
    } //catch para tratar erro caso exista algum problema ao acessar o histórico.
  }

  // Salva o histórico atualizado localmente. 
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_history.map((e) => e.toJson()).toList());
      await prefs.setString('history', encoded);
    } catch (e) {
      debugPrint('Erro ao salvar histórico: $e');
    }
  }
}
