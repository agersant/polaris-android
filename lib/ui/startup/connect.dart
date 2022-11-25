import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/strings.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class ConnectForm extends StatefulWidget {
  const ConnectForm({Key? key}) : super(key: key);

  @override
  State<ConnectForm> createState() => _ConnectFormState();
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
                return ElevatedButton(onPressed: _onConnectPressed, child: const Text(connectButtonLabel));
              })),
        ],
      ),
    );
  }

  Future _onConnectPressed() async {
    try {
      await _connectionManager.connect(_textEditingController.text);
    } on connection.Error catch (e) {
      _handleError(e);
    }
  }

  void _handleError(connection.Error error) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final collectionCache = getIt<CollectionCache>();
    final connectionManager = getIt<connection.Manager>();
    // TODO require some cached audio, not just collection cache
    final hasOfflineData = collectionCache.flattenDirectory(connectionManager.url ?? '', '')?.isNotEmpty == true;

    final SnackBarAction? offlineModeAction;
    if (hasOfflineData) {
      offlineModeAction = SnackBarAction(
        label: offlineModeButtonLabel,
        onPressed: connectionManager.startOffline,
      );
    } else {
      offlineModeAction = null;
    }

    final SnackBarAction? action;
    final String errorText;
    switch (error) {
      case connection.Error.unsupportedAPIVersion:
        errorText = errorAPIVersion;
        action = offlineModeAction;
        break;
      case connection.Error.connectionAlreadyInProgress:
        errorText = errorAlreadyConnecting;
        action = null;
        break;
      case connection.Error.networkError:
        errorText = errorNetwork;
        action = offlineModeAction;
        break;
      case connection.Error.requestFailed:
        errorText = errorRequestFailed;
        action = offlineModeAction;
        break;
      case connection.Error.requestTimeout:
        errorText = errorTimeout;
        action = offlineModeAction;
        break;
      case connection.Error.unknownError:
        errorText = errorUnknown;
        action = offlineModeAction;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorText),
      action: action,
    ));
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
