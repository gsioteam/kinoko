
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../localizations/localizations.dart';

class NoData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text(
          kt(context, 'no_data'),
          style: TextStyle(
              fontFamily: 'DancingScript',
              fontSize: 24,
              color: Theme.of(context).disabledColor,
              shadows: [
                Shadow(
                    color: Theme.of(context).colorScheme.surface,
                    offset: Offset(1, 1)
                ),
              ]
          ),
        ),
      ),
    );
  }
}