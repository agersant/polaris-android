import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/connection.dart' as connection;
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

final errorAPIVersion = 'The Polaris server responded but uses an incompatible API version.';
final errorAlreadyConnecting = 'Please wait while the connection is being established.';
final errorNetwork = 'The Polaris server could not be reached.';
final errorRequestFailed = 'The Polaris server sent an unexpected response.';
final errorUnknown = 'An unknown error occured.';

final serverURLFieldLabel = 'Server URL';
final connectButtonLabel = 'CONNECT';

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
            decoration: InputDecoration(
                icon: Icon(Icons.desktop_windows), labelText: serverURLFieldLabel, hintText: "Polaris server address"),
          ),
          Padding(
              padding: EdgeInsets.only(top: 32),
              child: Consumer<connection.Manager>(builder: (context, connectionStore, child) {
                return connectionStore.state == connection.State.connecting
                    ? CircularProgressIndicator()
                    : ElevatedButton(child: Text(connectButtonLabel), onPressed: _onConnectPressed);
              })),
        ],
      ),
    );
  }

  _onConnectPressed() async {
    try {
      await getIt<connection.Manager>().connect(_textEditingController.text);
    } catch (e) {}
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}

mixin ConnectionErrorHandler<T extends StatefulWidget> on State<T> {
  StreamSubscription<connection.Error> _connectionErrorStream;

  @override
  void initState() {
    super.initState();
    _connectionErrorStream = getIt<connection.Manager>().errorStream.listen((e) => handleError(e));
  }

  void handleError(connection.Error error) {
    Scaffold.of(context).removeCurrentSnackBar();
    switch (error) {
      case connection.Error.unsupportedAPIVersion:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorAPIVersion)));
        break;
      case connection.Error.connectionAlreadyInProgress:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorAlreadyConnecting)));
        break;
      case connection.Error.networkError:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorNetwork)));
        break;
      case connection.Error.requestFailed:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorRequestFailed)));
        break;
      case connection.Error.unknownError:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorUnknown)));
        break;
    }
  }

  void dispose() {
    _connectionErrorStream.cancel();
    super.dispose();
  }
}
