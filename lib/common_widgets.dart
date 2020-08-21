import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twtxt_flutter/viewmodels.dart';

import 'models.dart';

class Avatar extends StatelessWidget {
  final String imageUrl;

  const Avatar({Key key, this.imageUrl}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return CircleAvatar();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(backgroundImage: imageProvider);
      },
      placeholder: (context, url) => CircularProgressIndicator(),
    );
  }
}

class AuthWidgetBuilder extends StatelessWidget {
  const AuthWidgetBuilder({Key key, @required this.builder}) : super(key: key);
  final Widget Function(BuildContext, AsyncSnapshot<User>) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User>(
      stream: context.watch<AuthViewModel>().user,
      builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
        final User user = snapshot.data;
        if (user != null) {
          return MultiProvider(
            providers: [
              Provider<User>.value(value: user),
            ],
            child: builder(context, snapshot),
          );
        }
        return builder(context, snapshot);
      },
    );
  }
}
