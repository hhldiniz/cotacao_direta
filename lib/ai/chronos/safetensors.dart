import 'dart:convert';
import 'dart:typed_data';

/// One tensor read from a safetensors file: its shape and its values, flattened
/// in row-major order (the last dimension varies fastest, as in PyTorch).
class SafeTensor {
  final List<int> shape;
  final Float32List data;

  const SafeTensor(this.shape, this.data);

  int get length => data.length;
}

/// Reader for the safetensors format, the one Hugging Face publishes model
/// weights in.
///
/// The format is simple on purpose: 8 bytes with the size of a JSON header
/// (little-endian), the header itself — name, dtype, shape and byte range of
/// each tensor — and then the raw bytes of every tensor, back to back. There is
/// no code in it to run, unlike a pickled PyTorch checkpoint, which is why it is
/// safe to load a file downloaded from the internet.
///
/// Only float32 is supported: it is what the model the app uses is published
/// in. Any other dtype fails loudly instead of being misread.
class SafeTensors {
  final Map<String, SafeTensor> tensors;

  /// Free-form metadata stored under the `__metadata__` key of the header.
  final Map<String, String> metadata;

  const SafeTensors._(this.tensors, this.metadata);

  /// Parses [bytes], the whole content of a `.safetensors` file.
  ///
  /// When the data is 4-byte aligned in [bytes] — the common case, since the
  /// header is padded for it — the tensors are views over [bytes] and nothing
  /// is copied. Otherwise each tensor is copied out.
  factory SafeTensors.parse(Uint8List bytes) {
    if (bytes.lengthInBytes < 8)
      throw const FormatException("safetensors file too short");
    final view = ByteData.sublistView(bytes);
    // The length is a little-endian u64, read as two halves: the web build
    // has no 64-bit accessor (JavaScript numbers are doubles), and any real
    // header fits in the low half anyway.
    final lowHalf = view.getUint32(0, Endian.little);
    final highHalf = view.getUint32(4, Endian.little);
    if (highHalf != 0)
      throw const FormatException("invalid safetensors header length");
    final headerLength = lowHalf;
    final dataStart = 8 + headerLength;
    if (headerLength <= 0 || dataStart > bytes.lengthInBytes)
      throw const FormatException("invalid safetensors header length");

    final Object? header;
    try {
      header = jsonDecode(utf8.decode(bytes.sublist(8, dataStart)));
    } on FormatException {
      throw const FormatException("invalid safetensors header");
    }
    if (header is! Map<String, dynamic>)
      throw const FormatException("safetensors header is not a JSON object");

    final tensors = <String, SafeTensor>{};
    final metadata = <String, String>{};
    for (final entry in header.entries) {
      if (entry.key == "__metadata__") {
        final values = entry.value;
        if (values is Map) {
          values.forEach((key, value) => metadata["$key"] = "$value");
        }
        continue;
      }
      tensors[entry.key] = _readTensor(entry.key, entry.value, bytes, dataStart);
    }
    return SafeTensors._(Map.unmodifiable(tensors), Map.unmodifiable(metadata));
  }

  static SafeTensor _readTensor(
      String name, Object? description, Uint8List bytes, int dataStart) {
    if (description is! Map)
      throw FormatException("tensor $name has no description");
    final dtype = description["dtype"];
    if (dtype != "F32")
      throw FormatException("tensor $name is $dtype; only F32 is supported");

    final shape = (description["shape"] as List).cast<int>();
    final offsets = (description["data_offsets"] as List).cast<int>();
    final begin = dataStart + offsets[0];
    final end = dataStart + offsets[1];
    final count = shape.fold<int>(1, (total, size) => total * size);
    if (offsets[0] < 0 ||
        end > bytes.lengthInBytes ||
        end - begin != count * Float32List.bytesPerElement)
      throw FormatException("tensor $name has an invalid byte range");

    final absoluteOffset = bytes.offsetInBytes + begin;
    final Float32List data;
    if (absoluteOffset % Float32List.bytesPerElement == 0 &&
        Endian.host == Endian.little) {
      data = bytes.buffer.asFloat32List(absoluteOffset, count);
    } else {
      final source = ByteData.sublistView(bytes, begin, end);
      data = Float32List(count);
      for (var index = 0; index < count; index++) {
        data[index] = source.getFloat32(index * 4, Endian.little);
      }
    }
    return SafeTensor(List.unmodifiable(shape), data);
  }

  /// The tensor called [name], checked against [shape] when given.
  SafeTensor require(String name, [List<int>? shape]) {
    final tensor = tensors[name];
    if (tensor == null) throw FormatException("missing tensor $name");
    if (shape != null &&
        (tensor.shape.length != shape.length ||
            !Iterable.generate(shape.length)
                .every((index) => tensor.shape[index] == shape[index])))
      throw FormatException(
          "tensor $name has shape ${tensor.shape}, expected $shape");
    return tensor;
  }
}
