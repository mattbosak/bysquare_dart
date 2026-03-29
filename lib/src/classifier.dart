/// Encodes multiple classifier options into a single integer by summing them.
///
/// Used primarily for combining month flags in standing orders.
///
/// ```dart
/// encodeOptions([Month.january, Month.july, Month.october]); // → 577
/// ```
int encodeOptions(List<int> options) =>
    options.fold(0, (sum, option) => sum + option);

/// Decodes a summed classifier value back into individual flag values.
///
/// Returns the constituent powers-of-two in descending order.
///
/// ```dart
/// decodeOptions(577); // → [512, 64, 1]  (October, July, January)
/// ```
List<int> decodeOptions(int sum) {
  if (sum == 0) return const [];

  final classifiers = <int>[];
  final totalOptions = sum.bitLength; // position of highest set bit

  for (int i = 1; i <= totalOptions; i++) {
    final next = 1 << (totalOptions - i);
    if (next <= sum) {
      sum -= next;
      classifiers.add(next);
    }
  }

  return classifiers;
}
