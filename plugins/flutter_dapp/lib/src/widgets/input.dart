
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../dapp_state.dart';

typedef InputChangedCallback = void Function(String newText);
typedef InputSubmitCallback = void Function(String newText);

class Input extends StatefulWidget {

  final String? placeholder;
  final String text;
  final bool autofocus;
  final InputChangedCallback? onChange;
  final InputSubmitCallback? onSubmit;
  final TextStyle? style;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;

  Input({
    Key? key,
    this.placeholder,
    this.text = "",
    this.autofocus = false,
    this.onChange,
    this.onSubmit,
    this.style,
    this.onFocus,
    this.onBlur,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InputState();
}

class _InputState extends DAppState<Input> {

  late TextEditingController controller;
  late FocusNode focusNode;

  _InputState() {
    registerMethod("focus", () {
      focusNode.requestFocus();
    });
    registerMethod("blur", () {
      focusNode.unfocus();
    });
    registerMethod("submit", () {
      focusNode.unfocus();
      widget.onSubmit?.call(controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration.collapsed(
        hintText: widget.placeholder,
      ),
      autofocus: widget.autofocus,
      onChanged: widget.onChange,
      onSubmitted: widget.onSubmit,
      style: widget.style,
      focusNode: focusNode,
    );
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.text);
    focusNode = FocusNode();
    focusNode.addListener(_onFocusUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    focusNode.dispose();
  }

  @override
  void didUpdateWidget(covariant Input oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != controller.text) {
      controller.text = widget.text;
    }
  }

  void _onFocusUpdate() {
    if (focusNode.hasFocus) {
      widget.onFocus?.call();
    } else {
      widget.onBlur?.call();
    }
  }
}