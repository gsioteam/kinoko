

import 'package:flutter/material.dart';

abstract class DListView {

  static Widget builder({
    Key? key,
    required IndexedWidgetBuilder builder,
    required int itemCount,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return ListView.builder(
      key: key,
      itemBuilder: builder,
      itemCount: itemCount,
      padding: padding,
    );
  }

  static Widget children({
    Key? key,
    required List<Widget> children,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return ListView(
      key: key,
      children: children,
      padding: padding,
    );
  }
}

abstract class DSliverListView {
  static Widget builder({
    Key? key,
    required IndexedWidgetBuilder builder,
    required int itemCount,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        builder,
        childCount: itemCount,
      ),
    );
  }

  static Widget children({
    Key? key,
    required List<Widget> children,
  }) {
    return SliverList(
      delegate: SliverChildListDelegate(
        children
      ),
    );
  }
}