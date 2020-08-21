import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:twtxt_flutter/api.dart';
import 'package:twtxt_flutter/models.dart';
import 'package:twtxt_flutter/viewmodels.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:twtxt_flutter/common_widgets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final api = Api(http.Client(), FlutterSecureStorage());
    return MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider(create: (_) => AuthViewModel(api)),
      ],
      child: AuthWidgetBuilder(
        builder: (_, snapshot) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AuthWidget(snapshot: snapshot),
          theme: ThemeData(
            primaryColor: Colors.white,
            appBarTheme: AppBarTheme(
              elevation: 0.5,
              color: Colors.grey[50],
            ),
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  Future _loginFuture;
  final _passwordTextController = TextEditingController();
  final _podURLController = TextEditingController();
  final _usernameTextController = TextEditingController();

  Future _handleLogin(BuildContext context) async {
    try {
      await context.read<AuthViewModel>().login(
            _usernameTextController.text,
            _passwordTextController.text,
            _podURLController.text,
          );
    } catch (e) {
      var message = 'Unexpected error';
      if (e is http.ClientException) {
        message = e.message;
      }
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
      rethrow;
    }
  }

  String requiredFieldValidator(String value) {
    if (value.isEmpty) {
      return 'Required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Twtxt')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 16),
                TextFormField(
                  validator: requiredFieldValidator,
                  controller: _usernameTextController,
                  autofillHints: [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: 'Username',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                TextFormField(
                  validator: requiredFieldValidator,
                  controller: _passwordTextController,
                  autofillHints: [AutofillHints.password],
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                TextFormField(
                  autofillHints: [AutofillHints.url],
                  validator: requiredFieldValidator,
                  controller: _podURLController,
                  decoration: InputDecoration(
                    labelText: 'Pod URL',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                SizedBox(height: 16),
                FutureBuilder(
                  future: _loginFuture,
                  builder: (context, snapshot) {
                    Widget child = const Text('Login');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    return RaisedButton(
                      onPressed: () {
                        if (!_formKey.currentState.validate()) return;

                        setState(() {
                          _loginFuture = _handleLogin(context);
                        });
                      },
                      child: child,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    return SafeArea(
      child: Consumer<Api>(
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
              child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          );
        },
        child: Timeline(),
      ),
    );
  }
}

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
      appBar: AppBar(
        textTheme: Theme.of(context).textTheme,
        title: const Text('Twtxt'),
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
              child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).primaryColor,
              ),
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
                          styleSheet: MarkdownStyleSheet(
                            textScaleFactor: 1.2,
                          ),
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

class NewTwt extends StatefulWidget {
  const NewTwt({Key key, this.initialText = ''}) : super(key: key);

  final String initialText;

  @override
  _NewTwtState createState() => _NewTwtState();
}

class _NewTwtState extends State<NewTwt> {
  bool _canSubmit = false;
  Future _savePostFuture;
  TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _textController.addListener(() {
      setState(() {
        _canSubmit = _textController.text.trim().length > 0;
      });
    });
  }

  void submitPost() {
    setState(() {
      _savePostFuture = context
          .read<Api>()
          .savePost(_textController.text)
          .then((value) => Navigator.pop(context, true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FutureBuilder<Object>(
          future: _savePostFuture,
          builder: (context, snapshot) {
            Widget label = const Text("Post");

            if (snapshot.connectionState == ConnectionState.waiting)
              label = SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );

            return FloatingActionButton.extended(
              label: label,
              elevation: _canSubmit ? 2 : 0,
              backgroundColor:
                  _canSubmit ? null : Theme.of(context).disabledColor,
              onPressed: _canSubmit ? submitPost : null,
            );
          }),
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<User>(
          builder: (contxt, user, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(
                imageUrl: user.imageUrl,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: TextField(
                  maxLines: 8,
                  controller: _textController,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
