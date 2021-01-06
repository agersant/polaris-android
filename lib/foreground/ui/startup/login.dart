import 'dart:async';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:get_it/get_it.dart';
import 'package:polaris/foreground/authentication.dart' as authentication;
import 'package:polaris/foreground/connection.dart' as connection;
import 'package:polaris/foreground/ui/strings.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with AuthenticationErrorHandler {
  final _usernameEditingController = TextEditingController();
  final _passwordEditingController = TextEditingController();
  final authentication.Manager _authenticationManager = getIt<authentication.Manager>();

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: _usernameEditingController,
            decoration: InputDecoration(
              icon: Icon(Icons.person),
              labelText: usernameFieldLabel,
            ),
          ),
          TextFormField(
            controller: _passwordEditingController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              icon: Icon(Icons.lock),
              labelText: passwordFieldLabel,
            ),
          ),
          Padding(
              padding: EdgeInsets.only(top: 32),
              child: Consumer<authentication.Manager>(builder: (context, authenticationManager, child) {
                if (authenticationManager.state != authentication.State.unauthenticated) {
                  return CircularProgressIndicator();
                }
                return Row(
                  children: [
                    FlatButton(onPressed: _onDisconnectPressed, child: Text(disconnectButtonLabel)),
                    Spacer(),
                    ElevatedButton(onPressed: _onLoginPressed, child: Text(loginButtonLabel)),
                  ],
                );
              })),
        ],
      ),
    );
  }

  _onDisconnectPressed() async {
    getIt<connection.Manager>().disconnect();
  }

  _onLoginPressed() async {
    try {
      final username = _usernameEditingController.text;
      final password = _passwordEditingController.text;
      await _authenticationManager.authenticate(username, password);
    } catch (e) {}
  }

  @override
  void dispose() {
    _usernameEditingController.dispose();
    super.dispose();
  }
}

mixin AuthenticationErrorHandler<T extends StatefulWidget> on State<T> {
  StreamSubscription<authentication.Error> _authenticationErrorStream;

  @override
  void initState() {
    super.initState();
    _authenticationErrorStream = getIt<authentication.Manager>().errorStream.listen((e) => handleError(e));
  }

  void handleError(authentication.Error error) {
    Scaffold.of(context).removeCurrentSnackBar();
    switch (error) {
      case authentication.Error.authenticationAlreadyInProgress:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorAlreadyAuthenticating)));
        break;
      case authentication.Error.incorrectCredentials:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorIncorrectCredentials)));
        break;
      case authentication.Error.requestFailed:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorRequestFailed)));
        break;
      case authentication.Error.unknownError:
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorUnknown)));
        break;
    }
  }

  void dispose() {
    _authenticationErrorStream.cancel();
    super.dispose();
  }
}
