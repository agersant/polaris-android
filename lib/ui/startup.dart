import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/store/connection.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

class StartupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget logo = Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Image(image: AssetImage('assets/images/logo.png'))),
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
        Consumer<ConnectionStore>(
          builder: (context, connection, child) {
            return Text(connection.state.toString());
          },
        ),
        Expanded(
          flex: 75,
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: serverForm,
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
