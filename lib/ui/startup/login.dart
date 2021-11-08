import 'package:flutter/material.dart' hide ConnectionState;
import 'package:get_it/get_it.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/strings.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
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
            decoration: const InputDecoration(
              icon: Icon(Icons.person),
              labelText: usernameFieldLabel,
            ),
          ),
          TextFormField(
            controller: _passwordEditingController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              icon: Icon(Icons.lock),
              labelText: passwordFieldLabel,
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Consumer<authentication.Manager>(builder: (context, authenticationManager, child) {
                if (authenticationManager.state != authentication.State.unauthenticated) {
                  return const CircularProgressIndicator();
                }
                return Row(
                  children: [
                    TextButton(onPressed: _onDisconnectPressed, child: const Text(disconnectButtonLabel)),
                    const Spacer(),
                    ElevatedButton(onPressed: _onLoginPressed, child: const Text(loginButtonLabel)),
                  ],
                );
              })),
        ],
      ),
    );
  }

  Future _onDisconnectPressed() async {
    getIt<connection.Manager>().disconnect();
  }

  Future _onLoginPressed() async {
    final username = _usernameEditingController.text;
    final password = _passwordEditingController.text;
    try {
      await _authenticationManager.authenticate(username, password);
    } on authentication.Error catch (e) {
      _handleError(e);
    }
  }

  void _handleError(authentication.Error error) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    switch (error) {
      case authentication.Error.authenticationAlreadyInProgress:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorAlreadyAuthenticating)));
        break;
      case authentication.Error.incorrectCredentials:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorIncorrectCredentials)));
        break;
      case authentication.Error.requestFailed:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorRequestFailed)));
        break;
      case authentication.Error.unknownError:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(errorUnknown)));
        break;
    }
  }

  @override
  void dispose() {
    _usernameEditingController.dispose();
    super.dispose();
  }
}
