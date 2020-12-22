import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/store/connection.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class StartupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget logo = FractionallySizedBox(
      widthFactor: 0.5,
      child: SvgPicture.asset('assets/images/logo.svg',
          alignment: Alignment.bottomCenter, semanticsLabel: 'Polaris logo'),
    );

    Widget serverForm = Form(
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

    Widget loginForm = Form(
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

    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 50,
          child: logo,
        ),
        Expanded(
          flex: 75,
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Consumer<ConnectionStore>(
              builder: (context, connection, child) {
                switch (connection.state) {
                  case ConnectionState.disconnected:
                    return serverForm;
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
      ],
    ));
  }

  onConnectPressed() {
    getIt<ConnectionStore>().connect("http://example.com");
  }

  onLoginPressed() {}
}
