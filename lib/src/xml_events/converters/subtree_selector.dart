library xml_events.converters.subtree_selector;

import 'dart:convert' show ChunkedConversionSink;

import '../../xml/utils/exceptions.dart';
import '../../xml/utils/predicate.dart';
import '../event.dart';
import '../events/end_element_event.dart';
import '../events/start_element_event.dart';
import 'list_converter.dart';

/// A converter that selects [XmlEvent] objects that are part of a subtree
/// started by an [XmlStartElementEvent] satisfying the provided predicate.
class XmlSubtreeSelector extends XmlListConverter<XmlEvent, XmlEvent> {
  final Predicate<XmlStartElementEvent> predicate;

  const XmlSubtreeSelector(this.predicate);

  @override
  ChunkedConversionSink<List<XmlEvent>> startChunkedConversion(
          Sink<List<XmlEvent>> sink) =>
      _XmlSubtreeSelectorSink(sink, predicate);
}

class _XmlSubtreeSelectorSink extends ChunkedConversionSink<List<XmlEvent>> {
  final Sink<List<XmlEvent>> sink;
  final Predicate<XmlStartElementEvent> predicate;
  final List<XmlStartElementEvent> stack = [];

  _XmlSubtreeSelectorSink(this.sink, this.predicate);

  @override
  void add(List<XmlEvent> chunk) {
    final result = <XmlEvent>[];
    for (final event in chunk) {
      if (stack.isEmpty) {
        if (event is XmlStartElementEvent && predicate(event)) {
          if (!event.isSelfClosing) {
            stack.add(event);
          }
          result.add(event);
        }
      } else {
        if (event is XmlStartElementEvent && !event.isSelfClosing) {
          stack.add(event);
        } else if (event is XmlEndElementEvent) {
          XmlTagException.checkClosingTag(stack.last.name, event.name);
          stack.removeLast();
        }
        result.add(event);
      }
    }
    if (result.isNotEmpty) {
      sink.add(result);
    }
  }

  @override
  void close() {
    sink.close();
  }
}