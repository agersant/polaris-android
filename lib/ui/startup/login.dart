import 'package:flutter/material.dart' hide ConnectionState;
import 'package:get_it/get_it.dart';
import 'package:polaris/manager/connection.dart' as connection;

final usernameFieldLabel = 'Username';
final passwordFieldLabel = 'Password';
final disconnectButtonLabel = 'DISCONNECT';
final loginButtonLabel = 'LOGIN';

final getIt = GetIt.instance;

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameEditingController = TextEditingController();
  final _passwordEditingController = TextEditingController();

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
              padding: EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  FlatButton(onPressed: _onDisconnectPressed, child: Text(disconnectButtonLabel)),
                  Spacer(),
                  ElevatedButton(onPressed: _onLoginPressed, child: Text(loginButtonLabel)),
                ],
              ))
        ],
      ),
    );
  }

  _onDisconnectPressed() async {
    getIt<connection.Manager>().disconnect();
  }

  _onLoginPressed() async {}

  @override
  void dispose() {
    _usernameEditingController.dispose();
    super.dispose();
  }
}
