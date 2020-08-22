import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;

import '../common_widgets.dart';
import '../models.dart';
import '../viewmodels.dart';
import 'newtwt.dart';

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _page());
  }

  void _page() async {
    try {
      context.read<TimelineViewModel>().gotoNextPage();
    } on http.ClientException catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Consumer<User>(builder: (context, user, _) {
              return UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: Avatar(
                    imageUrl: user.imageUrl,
                    radius: 34,
                  ),
                ),
                accountName: Text(user.username),
                accountEmail: null,
              );
            }),
          ],
        ),
      ),
      appBar: AppBar(
        textTheme: Theme.of(context).textTheme,
        title: const Text('Timeline'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            onPressed: context.watch<AuthViewModel>().logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            if (await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewTwt(),
                  ),
                ) ??
                false) {
              context.read<TimelineViewModel>().fetchNewPost();
            }
          },
        ),
      ),
      body: Consumer2<TimelineViewModel, User>(
        builder: (context, timelineViewModel, user, _) {
          if (timelineViewModel.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final twts = timelineViewModel.twts;

          return RefreshIndicator(
            onRefresh: timelineViewModel.refreshPost,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              separatorBuilder: (context, index) {
                return Divider();
              },
              itemCount: twts.length,
              itemBuilder: (context, index) {
                final twt = twts[index];
                print(twt.twter.imageUrl);
                return ListTile(
                  isThreeLine: true,
                  leading: Avatar(
                      // This makes it so that we only display images from the pod we're currently logged in
                      imageUrl: twt.twter.uri.authority == user.podURL.authority
                          ? twt.twter.imageUrl
                          : null),
                  title: Text(
                    twt.twter.nick,
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: MarkdownBody(
                          styleSheet: MarkdownStyleSheet(textScaleFactor: 1.2),
                          onTapLink: (link) {
                            print(link);
                          },
                          data: twt.sanitizedTxt,
                          extensionSet: md.ExtensionSet.gitHubWeb,
                        ),
                      ),
                      Divider(),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NewTwt(
                                        initialText:
                                            twt.replyText(user.username),
                                      ),
                                    ),
                                  ) ??
                                  false) {
                                timelineViewModel.fetchNewPost();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                "Reply",
                                style: Theme.of(context).textTheme.button,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
