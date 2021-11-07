

class PickerItem<T> {
  final String label;
  final T value;

  PickerItem(this.label, this.value);

  @override
  String toString() => label;
}