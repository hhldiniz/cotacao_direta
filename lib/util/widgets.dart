import 'package:flutter/widgets.dart';

class StatefulWrapper extends StatefulWidget {
  final Widget _child;
  final Function _init;
  final Function _dispose;

  StatefulWrapper(this._child, this._init, this._dispose);

  @override
  State<StatefulWidget> createState() =>
      _StatefulWrapperState(_child, _init, _dispose);
}

class _StatefulWrapperState extends State<StatefulWrapper> {
  final Widget _child;
  final Function _init;
  final Function _dispose;

  _StatefulWrapperState(this._child, this._init, this._dispose);

  @override
  Widget build(BuildContext context) => _child;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}
