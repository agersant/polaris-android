import 'package:flutter/material.dart' hide ConnectionState;
import 'package:polaris/store/connection.dart';

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
            decoration: const InputDecoration(
              icon: Icon(Icons.person),
              labelText: "Username",
            ),
          ),
          TextFormField(
            controller: _passwordEditingController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              icon: Icon(Icons.lock),
              labelText: "Password",
            ),
          ),
          Padding(
              padding: EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  FlatButton(
                      onPressed: _onDisconnectPressed,
                      child: Text("DISCONNECT")),
                  Spacer(),
                  ElevatedButton(
                      onPressed: _onLoginPressed, child: Text("LOGIN")),
                ],
              ))
        ],
      ),
    );
  }

  _onDisconnectPressed() async {
    getIt<ConnectionStore>().disconnect();
  }

  _onLoginPressed() async {}

  @override
  void dispose() {
    _usernameEditingController.dispose();
    super.dispose();
  }
}
