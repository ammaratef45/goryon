import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../models.dart';
import '../viewmodels.dart';
import 'login.dart';
import 'timeline.dart';

class AuthWidget extends StatefulWidget {
  const AuthWidget({Key key, this.snapshot}) : super(key: key);

  final AsyncSnapshot<User> snapshot;

  @override
  _AuthWidgetState createState() => _AuthWidgetState();
}

class _AuthWidgetState extends State<AuthWidget> {
  StreamSubscription _userSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userSub == null) {
      _userSub = context
          .read<AuthViewModel>()
          .user
          .where((user) => user == null)
          .listen((_) => Navigator.popUntil(context, (route) => route.isFirst));
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Api>(
      builder: (context, api, child) {
        if (widget.snapshot.connectionState == ConnectionState.active) {
          return widget.snapshot.hasData
              ? ChangeNotifierProvider(
                  create: (_) => TimelineViewModel(api),
                  child: child,
                )
              : Login();
        }

        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      child: Timeline(),
    );
  }
}
