import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/store/connection.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class StartupPage extends StatelessWidget {
  final Widget _logo = SvgPicture.asset('assets/images/logo.svg',
      semanticsLabel: 'Polaris logo');

  Widget get _connectForm {
    return Form(
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
                icon: Icon(Icons.desktop_windows),
                labelText: "Server URL",
                hintText: "Polaris server address"),
          ),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: ElevatedButton(
                  onPressed: onConnectPressed, child: Text("CONNECT")))
        ],
      ),
    );
  }

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
                        return _connectForm;
                      case ConnectionState.connecting:
                        return Align(
                            alignment: Alignment.topCenter,
                            child: CircularProgressIndicator());
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

  onConnectPressed() {
    getIt<ConnectionStore>().connect("http://example.com");
  }

  onLoginPressed() {}
}
