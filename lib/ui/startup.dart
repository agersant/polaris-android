import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svg/flutter_svg.dart';
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
    } on ConnectionStoreError catch (e) {
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
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}

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
              child: ElevatedButton(
                  onPressed: _onLoginPressed, child: Text("LOGIN")))
        ],
      ),
    );
  }

  _onLoginPressed() async {}

  @override
  void dispose() {
    _usernameEditingController.dispose();
    super.dispose();
  }
}

class StartupPage extends StatelessWidget {
  final Widget _logo = SvgPicture.asset('assets/images/logo.svg',
      semanticsLabel: 'Polaris logo');

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: OrientationBuilder(builder: (context, orientation) {
      EdgeInsets padding = orientation == Orientation.portrait
          ? const EdgeInsets.symmetric(horizontal: 48.0)
          : const EdgeInsets.all(0);
      Axis direction =
          orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal;

      return Padding(
        padding: padding,
        child: Flex(
          direction: direction,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 40),
            Expanded(flex: 50, child: _logo),
            Spacer(flex: 20),
            Expanded(
              flex: 100,
              child: IntrinsicHeight(
                child: Consumer<ConnectionStore>(
                  builder: (context, connection, child) {
                    switch (connection.state) {
                      case ConnectionState.disconnected:
                      case ConnectionState.connecting:
                        return ConnectForm();
                      case ConnectionState.connected:
                      default:
                        return LoginForm();
                    }
                  },
                ),
              ),
            ),
            Spacer(flex: 40),
          ],
        ),
      );
    }));
  }
}
