import 'package:animations/animations.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/startup/connect.dart';
import 'package:polaris/ui/startup/login.dart';
import 'package:provider/provider.dart';

enum StartupState {
  reconnecting,
  connect,
  login,
}

class StartupPage extends StatelessWidget {
  final Widget _logo = SvgPicture.asset('assets/images/logo.svg', semanticsLabel: 'Polaris logo');

  StartupPage({Key? key}) : super(key: key);

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
  }

  Widget _buildWidgetForState(StartupState state) {
    switch (state) {
      case StartupState.reconnecting:
        return const CircularProgressIndicator();
      case StartupState.connect:
        return const ConnectForm();
      case StartupState.login:
        return const LoginForm();
    }
  }

  Widget _buildContent() {
    return Consumer2<connection.Manager, authentication.Manager>(
      builder: (context, connectionManager, authenticationManager, child) {
        final state = _computeState(connectionManager.state, authenticationManager.state);
        final widget = _buildWidgetForState(state);
        return PageTransitionSwitcher(
            reverse: state == StartupState.connect,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: OrientationBuilder(builder: (context, orientation) {
      EdgeInsets padding =
          orientation == Orientation.portrait ? const EdgeInsets.symmetric(horizontal: 48.0) : const EdgeInsets.all(0);
      Axis direction = orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal;

      // TODO would be nicer if logo lined up with splash screen
      // for some kind of seemless transition

      return Padding(
        padding: padding,
        child: Flex(
          direction: direction,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 40),
            Expanded(flex: 50, child: _logo),
            const Spacer(flex: 20),
            Expanded(
              flex: 100,
              child: IntrinsicHeight(child: _buildContent()),
            ),
            const Spacer(flex: 40),
          ],
        ),
      );
    }));
  }
}
