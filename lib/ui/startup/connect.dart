import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/strings.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

// TODO allow bypassing connection + auth for offline mode

class ConnectForm extends StatefulWidget {
  const ConnectForm({Key? key}) : super(key: key);

  @override
  _ConnectFormState createState() => _ConnectFormState();
}

class _ConnectFormState extends State<ConnectForm> {
  late TextEditingController _textEditingController;
  final connection.Manager _connectionManager = getIt<connection.Manager>();

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: _connectionManager.url);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: _textEditingController,
            decoration: const InputDecoration(
                icon: Icon(Icons.desktop_windows), labelText: serverURLFieldLabel, hintText: "Polaris server address"),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Consumer<connection.Manager>(builder: (context, connectionManager, child) {
                if (connectionManager.state != connection.State.disconnected) {
                  return const CircularProgressIndicator();
                }
                return ElevatedButton(child: const Text(connectButtonLabel), onPressed: _onConnectPressed);
              })),
        ],
      ),
    );
  }

  _onConnectPressed() async {
    try {
      await _connectionManager.connect(_textEditingController.text);
    } on connection.Error catch (e) {
      _handleError(e);
    }
  }

  void _handleError(connection.Error error) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    switch (error) {
      case connection.Error.unsupportedAPIVersion:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorAPIVersion)));
        break;
      case connection.Error.connectionAlreadyInProgress:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorAlreadyConnecting)));
        break;
      case connection.Error.networkError:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorNetwork)));
        break;
      case connection.Error.requestFailed:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorRequestFailed)));
        break;
      case connection.Error.unknownError:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorUnknown)));
        break;
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
