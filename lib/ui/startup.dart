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
  final textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: textEditingController,
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
                        child: Text("CONNECT"), onPressed: onConnectPressed);
              })),
        ],
      ),
    );
  }

  onConnectPressed() async {
    try {
      await getIt<ConnectionStore>().connect(textEditingController.text);
    } catch (e) {}
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
}

class StartupPage extends StatelessWidget {
  final Widget _logo = SvgPicture.asset('assets/images/logo.svg',
      semanticsLabel: 'Polaris logo');

  Widget get _loginForm {
    return Form(
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              icon: Icon(Icons.person),
              labelText: "Username",
            ),
          ),
          TextFormField(
            decoration: const InputDecoration(
              icon: Icon(Icons.lock),
              labelText: "Password",
            ),
          ),
          Padding(
              padding: EdgeInsets.only(top: 24),
              child: ElevatedButton(
                  onPressed: onLoginPressed, child: Text("LOGIN")))
        ],
      ),
    );
  }

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
                        return Text("we gucci");
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

  onLoginPressed() {}
}
