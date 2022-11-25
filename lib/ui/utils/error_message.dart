import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final IconData icon;
  final void Function()? action;

  const ErrorMessage(
    this.message, {
    this.icon = Icons.error_outline,
    this.action,
    this.actionLabel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).textTheme.caption?.color,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(message),
            ),
          ],
        ),
        if (actionLabel != null && action != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: OutlinedButton(onPressed: action, child: Text(actionLabel!)),
          )
      ],
    );
  }
}
