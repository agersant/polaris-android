import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:get_it/get_it.dart';
import 'package:polaris/store/connection.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

final errorAPIVersion =
    'The Polaris server responded but uses an incompatible API version.';
final errorAlreadyConnecting =
    'Please wait while the connection is being established.';
final errorNetwork = 'The Polaris server could not be reached.';
final errorRequestFailed = 'The Polaris server sent an unexpected response.';
final errorUnknown = 'An unknown error occured.';

class ConnectForm extends StatefulWidget {
  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> with ConnectionErrorHandler {
  final _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: _textEditingController,
            decoration: const InputDecoration(
                icon: Icon(Icons.desktop_windows),
                labelText: "Server URL",
                hintText: "Polaris server address"),
          ),
          Padding(
              padding: EdgeInsets.only(top: 32),
              child: Consumer<ConnectionStore>(
                  builder: (context, connectionStore, child) {
                return connectionStore.state == ConnectionState.connecting
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        child: Text("CONNECT"), onPressed: _onConnectPressed);
              })),
        ],
      ),
    );
  }

  _onConnectPressed() async {
    try {
      await getIt<ConnectionStore>().connect(_textEditingController.text);
    } catch (e) {}
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}

mixin ConnectionErrorHandler<T extends StatefulWidget> on State<T> {
  StreamSubscription<ConnectionStoreError> _connectionErrorStream;

  @override
  void initState() {
    super.initState();
    _connectionErrorStream =
        getIt<ConnectionStore>().errorStream.listen((e) => handleError(e));
  }

  void handleError(ConnectionStoreError error) {
    Scaffold.of(context).removeCurrentSnackBar();
    switch (error) {
      case ConnectionStoreError.unsupportedAPIVersion:
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text(errorAPIVersion)));
        break;
      case ConnectionStoreError.connectionAlreadyInProgress:
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text(errorAlreadyConnecting)));
        break;
      case ConnectionStoreError.networkError:
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text(errorNetwork)));
        break;
      case ConnectionStoreError.requestFailed:
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text(errorRequestFailed)));
        break;
      case ConnectionStoreError.unknownError:
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text(errorUnknown)));
        break;
    }
  }

  void dispose() {
    _connectionErrorStream.cancel();
    super.dispose();
  }
}
