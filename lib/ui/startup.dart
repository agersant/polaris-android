import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              child: ElevatedButton(onPressed: example, child: Text("CONNECT")))
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
              child: ElevatedButton(onPressed: example, child: Text("LOGIN")))
        ],
      ),
    );

    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 50,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Image(image: AssetImage('assets/images/logo.png'))),
          ),
        ),
        Expanded(
          flex: 75,
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: loginForm,
          ),
        ),
      ],
    ));
  }

  example() {}
}
