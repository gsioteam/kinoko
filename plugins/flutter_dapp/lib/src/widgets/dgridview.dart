
import 'package:flutter/cupertino.dart';

abstract class DGridView extends StatelessWidget {

  static Widget builder({
    Key? key,
    required IndexedWidgetBuilder builder,
    required int itemCount,
    EdgeInsets padding = EdgeInsets.zero,
    int crossAxisCount = 4,
    double childAspectRatio = 1,
  }) {
    return GridView.builder(
      key: key,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: builder,
      itemCount: itemCount,
      padding: padding,
    );
  }

  static Widget children({
    Key? key,
    required List<Widget> children,
    EdgeInsets padding = EdgeInsets.zero,
    int crossAxisCount = 4,
    double childAspectRatio = 1,
  }) {
    return GridView(
      key: key,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      children: children,
      padding: padding,
    );
  }
}

abstract class DSliverGridView extends StatelessWidget {

  static Widget builder({
    Key? key,
    required IndexedWidgetBuilder builder,
    required int itemCount,
    int crossAxisCount = 4,
    double childAspectRatio = 1,
  }) {
    return SliverGrid(
      key: key,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        builder,
        childCount: itemCount,
      ),
    );
  }

  static Widget children({
    Key? key,
    required List<Widget> children,
    int crossAxisCount = 4,
    double childAspectRatio = 1,
  }) {
    return SliverGrid(
      key: key,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildListDelegate(
        children,
      ),
    );
  }
}