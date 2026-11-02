import 'package:flutter/material.dart';

import 'word_badge.dart';

/// Positions suggestions using the editable renderer's actual caret rectangle.
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
  OverlayEntry? _entry;
  String? _dismissed;
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
      final matches = widget.words
          .where((w) => matchesWord(w, wordPrefix(value)))
          .toList();
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
      final above = (point.dy - safeTop - 8).clamp(0.0, bottom - safeTop);
      final height = above >= 80
          ? above.clamp(80.0, 180.0)
          : (bottom - safeTop).clamp(50.0, 180.0);
      final top = (point.dy - height - 8).clamp(
        safeTop,
        (bottom - height).clamp(safeTop, bottom),
      );
      final left = (rtl ? point.dx - width : point.dx).clamp(
        12.0,
        media.size.width - width - 12,
      );
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
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) => true,
                  child: SingleChildScrollView(
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
        child: Container(key: _anchor, child: widget.child),
      );
}
