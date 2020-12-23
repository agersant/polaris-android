import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:get_it/get_it.dart';
import 'package:polaris/store/connection.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class ConnectForm extends StatefulWidget {
  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> {
  final _textEditingController = TextEditingController();
  StreamSubscription<ConnectionStoreError> _connectionErrorStream;

  @override
  void initState() {
    super.initState();
    _connectionErrorStream = getIt<ConnectionStore>().errorStream.listen((e) {
      Scaffold.of(context).removeCurrentSnackBar();
      switch (e) {
        case ConnectionStoreError.unsupportedAPIVersion:
          Scaffold.of(context).showSnackBar(SnackBar(
              content: Text(
                  "The Polaris server responded but uses an incompatible API version.")));
          break;
        case ConnectionStoreError.connectionAlreadyInProgress:
          Scaffold.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Please wait while the connection is being established.")));
          break;
        case ConnectionStoreError.networkError:
          Scaffold.of(context).showSnackBar(SnackBar(
              content: Text("The Polaris server could not be reached.")));
          break;
        case ConnectionStoreError.requestFailed:
          Scaffold.of(context).showSnackBar(SnackBar(
              content:
                  Text("The Polaris server sent an unexpected response.")));
          break;
        case ConnectionStoreError.unknownError:
          Scaffold.of(context).showSnackBar(
              SnackBar(content: Text("An unknown error occured.")));
          break;
      }
    });
  }

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
                  builder: (context, connection, child) {
                return connection.state == ConnectionState.connecting
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
    _connectionErrorStream.cancel();
    super.dispose();
  }
}
