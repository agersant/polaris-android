import 'package:animations/animations.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/authentication.dart' as authentication;
import 'package:polaris/platform/connection.dart' as connection;
import 'package:polaris/ui/startup/connect.dart';
import 'package:polaris/ui/startup/login.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

enum StartupState {
  reconnecting,
  connect,
  login,
}

class StartupPage extends StatelessWidget {
  final Widget _logo = SvgPicture.asset('assets/images/logo.svg', semanticsLabel: 'Polaris logo');

  StartupState _computeState(connection.State connectionState, authentication.State authenticationState) {
    switch (connectionState) {
      case connection.State.reconnecting:
        return StartupState.reconnecting;
      case connection.State.disconnected:
      case connection.State.connecting:
        return StartupState.connect;
      case connection.State.connected:
        switch (authenticationState) {
          case authentication.State.reauthenticating:
            return StartupState.reconnecting;
          case authentication.State.authenticating:
          case authentication.State.unauthenticated:
          case authentication.State.authenticated:
            return StartupState.login;
        }
    }
    return null;
  }

  Widget _buildWidgetForState(StartupState state) {
    switch (state) {
      case StartupState.reconnecting:
        return CircularProgressIndicator();
      case StartupState.connect:
        return ConnectForm();
      case StartupState.login:
        return LoginForm();
    }
    return null;
  }

  Widget _buildContent() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<connection.Manager>()),
        ChangeNotifierProvider.value(value: getIt<authentication.Manager>()),
      ],
      child: Consumer2<connection.Manager, authentication.Manager>(
        builder: (context, connectionManager, authenticationManager, child) {
          final state = _computeState(connectionManager.state, authenticationManager.state);
          final widget = _buildWidgetForState(state);
          return PageTransitionSwitcher(
              reverse: state != StartupState.login,
              transitionBuilder: (
                Widget child,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return SharedAxisTransition(
                  child: child,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                );
              },
              child: widget);

          // return Container();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: OrientationBuilder(builder: (context, orientation) {
      EdgeInsets padding =
          orientation == Orientation.portrait ? const EdgeInsets.symmetric(horizontal: 48.0) : const EdgeInsets.all(0);
      Axis direction = orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal;

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
              child: IntrinsicHeight(child: _buildContent()),
            ),
            Spacer(flex: 40),
          ],
        ),
      );
    }));
  }
}
