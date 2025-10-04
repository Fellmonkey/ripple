import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../config/appwrite_config.dart';

class AppwriteService {
  late final Client _client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  late final Functions functions;

  void initialize() {
    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId)
        .setSelfSigned(status: kDebugMode);

    account = Account(_client);
    databases = Databases(_client);
    storage = Storage(_client);
    functions = Functions(_client);
  }

  Client get client => _client;
}
