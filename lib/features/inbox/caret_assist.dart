import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'word_badge.dart';

/// Positions suggestions using the editable renderer's actual caret rectangle.
double mobileAssistHeight(MediaQueryData media) =>
    ((media.size.height -
                media.viewInsets.bottom -
                media.padding.vertical -
                kToolbarHeight) *
            .4)
        .clamp(0.0, 180.0);

class CaretAssist extends StatefulWidget {
  const CaretAssist({
    super.key,
    required this.controller,
    required this.focus,
    required this.words,
    required this.onWord,
    required this.child,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final List<String> words;
  final ValueChanged<String> onWord;
  final Widget child;
  @override
  State<CaretAssist> createState() => _CaretAssistState();
}

class _CaretAssistState extends State<CaretAssist> with WidgetsBindingObserver {
  final _anchor = GlobalKey();
  final _suggestionScroll = ScrollController();
  OverlayEntry? _entry;
  String? _dismissed;
  List<String> _matches = [];
  int _selected = 0;
  String _query = '';
  bool _controlling = false;
  bool get _desktop =>
      MediaQuery.sizeOf(context).width >= 760 &&
      MediaQuery.viewInsetsOf(context).bottom == 0;
  void _choose(String word) {
    widget.onWord(word);
    _dismissed = widget.controller.text;
    _hide();
  }

  bool _key(KeyEvent event) {
    if (event is KeyUpEvent && !HardwareKeyboard.instance.isControlPressed) {
      _controlling = false;
      _entry?.markNeedsBuild();
    }
    if (!mounted ||
        !widget.focus.hasFocus ||
        !_desktop ||
        _entry == null ||
        _matches.isEmpty ||
        event is KeyUpEvent) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isMetaPressed ||
        keyboard.isAltPressed ||
        keyboard.isShiftPressed) {
      return false;
    }
    if (!keyboard.isControlPressed) {
      _controlling = false;
      _entry?.markNeedsBuild();
      return false;
    }
    final composing = widget.controller.value.composing;
    if (composing.isValid && !composing.isCollapsed) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _dismissed = widget.controller.text;
      _hide();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final forward =
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowRight;
      _selected = _controlling
          ? (_selected + (forward ? 1 : -1)) % _matches.length
          : (forward ? 0 : _matches.length - 1);
      _controlling = true;
      _entry?.markNeedsBuild();
      return true;
    }
    if (_controlling &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _choose(_matches[_selected]);
      return true;
    }
    return false;
  }

  ScrollNotificationObserverState? _scrollObserver;
  void _scrolled(ScrollNotification notification) {
    _update();
  }

  @override
  void didChangeMetrics() => _update();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollObserver?.removeListener(_scrolled);
    _scrollObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollObserver?.addListener(_scrolled);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_update);
    widget.focus.addListener(_update);
  }

  void _hide() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  void _update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hide();
      if (!widget.focus.hasFocus || _dismissed == widget.controller.text) {
        return;
      }
      EditableTextState? editable;
      void visit(Element element) {
        if (element is StatefulElement && element.state is EditableTextState) {
          editable = element.state as EditableTextState;
        }
        element.visitChildren(visit);
      }

      (_anchor.currentContext as Element?)?.visitChildren(visit);
      if (editable == null) return;
      final value = widget.controller.value;
      final query = completionPrefix(value, widget.words);
      final matches = wordSuggestions(widget.words, query);
      if (_query != query) {
        _selected = 0;
        _controlling = false;
      }
      _query = query;
      _matches = matches;
      if (_selected >= matches.length) _selected = 0;
      if (matches.isEmpty) return;
      final render = editable!.renderEditable;
      final caret = render.getLocalRectForCaret(
        TextPosition(
          offset: value.selection.isValid
              ? value.selection.extentOffset
              : value.text.length,
        ),
      );
      final point = render.localToGlobal(caret.topLeft);
      final media = MediaQueryData.fromView(View.of(context));
      final width = (media.size.width - 24).clamp(0.0, 300.0);
      final bottom =
          media.size.height -
          media.viewInsets.bottom -
          media.padding.bottom -
          8;
      final safeTop = media.padding.top + kToolbarHeight + 8;
      if (bottom - safeTop < 50) return;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final height = _desktop
          ? (bottom - safeTop).clamp(50.0, 180.0)
          : mobileAssistHeight(media);
      final preferredTop = _desktop
          ? render.localToGlobal(caret.bottomLeft).dy + 4
          : bottom - height;
      final top = preferredTop.clamp(
        safeTop,
        (bottom - height).clamp(safeTop, bottom),
      );
      final left = _desktop
          ? (rtl ? point.dx - width - 8 : point.dx + 8).clamp(
              12.0,
              media.size.width - width - 12,
            )
          : (rtl ? media.size.width - width - 12 : 12.0);
      _entry = OverlayEntry(
        builder: (_) => Positioned(
          left: left,
          top: top,
          width: width,
          child: TextFieldTapRegion(
            child: Material(
              key: const ValueKey("assist-popup"),
              elevation: 6,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: height,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) => true,
                  child: SingleChildScrollView(
                    controller: _suggestionScroll,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '원소 어시스트',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              IconButton(
                                tooltip: '후보 닫기',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  _dismissed = widget.controller.text;
                                  _hide();
                                },
                                icon: const Icon(Icons.close, size: 16),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: matches
                                .map(
                                  (word) => WordBadge(
                                    key: ValueKey('suggestion-$word'),
                                    word: word,
                                    selected:
                                        _controlling &&
                                        matches.indexOf(word) == _selected,
                                    onTap: () {
                                      widget.onWord(word);
                                      _dismissed = widget.controller.text;
                                      _hide();
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_entry!);
    });
  }

  @override
  void dispose() {
    _suggestionScroll.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _scrollObserver?.removeListener(_scrolled);
    widget.controller.removeListener(_update);
    widget.focus.removeListener(_update);
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _update();
          return false;
        },
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) =>
              _key(event) ? KeyEventResult.handled : KeyEventResult.ignored,
          child: Container(key: _anchor, child: widget.child),
        ),
      );
}
