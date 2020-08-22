import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:twtxt_flutter/api.dart';
import 'package:twtxt_flutter/common_widgets.dart';
import 'package:twtxt_flutter/models.dart';
import 'package:twtxt_flutter/strings.dart';
import 'package:twtxt_flutter/viewmodels.dart';

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
        Provider(create: (_) => AppStrings()),
        Provider(create: (_) => AuthViewModel(api)),
      ],
      child: AuthWidgetBuilder(
        builder: (_, snapshot) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AuthWidget(snapshot: snapshot),
          theme: ThemeData(
            brightness: Brightness.light,
            appBarTheme: AppBarTheme(
              textTheme: TextTheme(
                headline6: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              iconTheme: IconThemeData(color: Colors.black),
              actionsIconTheme: IconThemeData(color: Colors.black),
              elevation: 0.5,
              color: Colors.grey[50],
            ),
            inputDecorationTheme: InputDecorationTheme(
              floatingLabelBehavior: FloatingLabelBehavior.never,
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
        padding: const EdgeInsets.all(32.0),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: ListView(
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
                  keyboardType: TextInputType.url,
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return RaisedButton(
                      onPressed: () {
                        if (!_formKey.currentState.validate()) return;

                        setState(() {
                          _loginFuture = _handleLogin(context);
                        });
                      },
                      child: const Text('Login'),
                    );
                  },
                ),
                SizedBox(height: 8),
                Builder(builder: (context) {
                  return FlatButton(
                    onPressed: () async {
                      if (await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => Register())) ??
                          false) {
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Successfully registered an account. You can now login',
                          ),
                        ));
                      }
                    },
                    child: const Text('Register'),
                  );
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordTextController = TextEditingController();
  final _podURLController = TextEditingController();
  Future _registerFuture;
  final _usernameTextController = TextEditingController();

  Future _handleRegister(BuildContext context) async {
    try {
      await context.read<Api>().register(
            _podURLController.text,
            _usernameTextController.text,
            _passwordTextController.text,
            _podURLController.text,
          );
      Navigator.pop(context, true);
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
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: ListView(
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
                  autofillHints: [AutofillHints.email],
                  validator: requiredFieldValidator,
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
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
                SizedBox(height: 32),
                FutureBuilder(
                  future: _registerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return RaisedButton(
                      onPressed: () {
                        if (!_formKey.currentState.validate()) return;

                        setState(() {
                          _registerFuture = _handleRegister(context);
                        });
                      },
                      child: const Text('Register'),
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

class NewTwt extends StatefulWidget {
  const NewTwt({Key key, this.initialText = ''}) : super(key: key);

  final String initialText;

  @override
  _NewTwtState createState() => _NewTwtState();
}

class _NewTwtState extends State<NewTwt> {
  bool _canSubmit = false;
  final _random = Random();
  Future _savePostFuture;
  TextEditingController _textController;
  String _twtPrompt;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _textController.buildTextSpan();
    _twtPrompt = _getTwtPrompt();
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

  String _getTwtPrompt() {
    final prompts = context.read<AppStrings>().twtPromtpts;
    return prompts[_random.nextInt(prompts.length)];
  }

  void _surroundTextSelection(String left, String right) {
    final currentTextValue = _textController.value.text;
    final selection = _textController.selection;
    final middle = selection.textInside(currentTextValue);
    final newTextValue = selection.textBefore(currentTextValue) +
        '$left$middle$right' +
        selection.textAfter(currentTextValue);

    _textController.value = _textController.value.copyWith(
      text: newTextValue,
      selection: TextSelection.collapsed(
        offset: selection.baseOffset + left.length + middle.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FutureBuilder(
          future: _savePostFuture,
          builder: (context, snapshot) {
            Widget label = const Text("Post");

            if (snapshot.connectionState == ConnectionState.waiting)
              label = SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
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
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: _twtPrompt,
                      ),
                      maxLines: 8,
                      controller: _textController,
                    ),
                    SizedBox(
                      height: 32,
                      child: Scrollbar(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            IconButton(
                              tooltip: 'Bold',
                              icon: Icon(Icons.format_bold),
                              onPressed: () => _surroundTextSelection(
                                '**',
                                '**',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Underline',
                              icon: Icon(Icons.format_italic),
                              onPressed: () => _surroundTextSelection(
                                '__',
                                '__',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Code',
                              icon: Icon(Icons.code),
                              onPressed: () => _surroundTextSelection(
                                '```',
                                '```',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Strikethrough',
                              icon: Icon(Icons.strikethrough_s_rounded),
                              onPressed: () => _surroundTextSelection(
                                '~~',
                                '~~',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Link',
                              icon: Icon(Icons.link_sharp),
                              onPressed: () => _surroundTextSelection(
                                '[title](https://',
                                ')',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
