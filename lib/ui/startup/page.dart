import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/store/connection.dart';
import 'package:polaris/ui/startup/connect.dart';
import 'package:polaris/ui/startup/login.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

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
                child: MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(
                        value: getIt<ConnectionStore>())
                  ],
                  child: Consumer<ConnectionStore>(
                    builder: (context, connection, child) {
                      switch (connection.state) {
                        case ConnectionState.reconnecting:
                          return Container();
                        case ConnectionState.disconnected:
                        case ConnectionState.connecting:
                          return ConnectForm();
                        case ConnectionState.connected:
                          return LoginForm();
                      }
                      return Container();
                    },
                  ),
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
