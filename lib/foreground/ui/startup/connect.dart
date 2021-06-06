import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/foreground/connection.dart' as connection;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/foreground/ui/strings.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

// TODO allow bypassing connection + auth for offline mode

class ConnectForm extends StatefulWidget {
  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> with ConnectionErrorHandler {
  late TextEditingController _textEditingController;
  final connection.Manager _connectionManager = getIt<connection.Manager>();
  final host.Manager _hostManager = getIt<host.Manager>();

  @override
  void initState() {
    super.initState();
    _textEditingController = new TextEditingController(text: _hostManager.url);
  }

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
              child: Consumer<connection.Manager>(builder: (context, connectionManager, child) {
                if (connectionManager.state != connection.State.disconnected) {
                  return CircularProgressIndicator();
                }
                return ElevatedButton(child: Text(connectButtonLabel), onPressed: _onConnectPressed);
              })),
        ],
      ),
    );
  }

  _onConnectPressed() async {
    try {
      await _connectionManager.connect(_textEditingController.text);
    } catch (e) {}
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}

mixin ConnectionErrorHandler<T extends StatefulWidget> on State<T> {
  late StreamSubscription<connection.Error> _connectionErrorStream;

  @override
  void initState() {
    super.initState();
    _connectionErrorStream = getIt<connection.Manager>().errorStream.listen((e) => handleError(e));
  }

  void handleError(connection.Error error) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    switch (error) {
      case connection.Error.unsupportedAPIVersion:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorAPIVersion)));
        break;
      case connection.Error.connectionAlreadyInProgress:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorAlreadyConnecting)));
        break;
      case connection.Error.networkError:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorNetwork)));
        break;
      case connection.Error.requestFailed:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorRequestFailed)));
        break;
      case connection.Error.unknownError:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorUnknown)));
        break;
    }
  }

  void dispose() {
    _connectionErrorStream.cancel();
    super.dispose();
  }
}
