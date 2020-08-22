import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../common_widgets.dart';
import '../models.dart';
import '../strings.dart';

class NewTwt extends StatefulWidget {
  const NewTwt({Key key, this.initialText = ''}) : super(key: key);

  final String initialText;

  @override
  _NewTwtState createState() => _NewTwtState();
}

class _NewTwtState extends State<NewTwt> {
  final _random = Random();
  bool _canSubmit = false;
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
                            IconButton(
                              tooltip: 'Image Link',
                              icon: Icon(Icons.image),
                              onPressed: () => _surroundTextSelection(
                                '![](https://',
                                ')',
                              ),
                            )
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
