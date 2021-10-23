import 'package:animations/animations.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polaris/foreground/authentication.dart' as authentication;
import 'package:polaris/foreground/connection.dart' as connection;
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/ui/startup/connect.dart';
import 'package:polaris/ui/startup/login.dart';
import 'package:provider/provider.dart';

enum StartupState {
  reconnecting,
  connect,
  login,
  startingService,
}

class StartupPage extends StatelessWidget {
  final Widget _logo = SvgPicture.asset('assets/images/logo.svg', semanticsLabel: 'Polaris logo');

  StartupState _computeState(
      connection.State connectionState, authentication.State authenticationState, polaris.State serviceState) {
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
            return StartupState.login;
          case authentication.State.authenticated:
            switch (serviceState) {
              case polaris.State.unavailable:
              case polaris.State.available:
                return StartupState.startingService;
            }
        }
    }
  }

  Widget _buildWidgetForState(StartupState state) {
    switch (state) {
      case StartupState.reconnecting:
        return CircularProgressIndicator();
      case StartupState.connect:
        return ConnectForm();
      case StartupState.login:
        return LoginForm();
      case StartupState.startingService:
        return CircularProgressIndicator();
    }
  }

  Widget _buildContent() {
    return Consumer3<connection.Manager, authentication.Manager, polaris.API>(
      builder: (context, connectionManager, authenticationManager, polarisAPI, child) {
        final state = _computeState(connectionManager.state, authenticationManager.state, polarisAPI.state);
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

        // return Container();
      },
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
