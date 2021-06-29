
import 'dart:ffi';
import 'dart:typed_data' as TypedData;

import 'package:ffi/ffi.dart';

import 'core.dart';

class Data extends Base {
  static reg() {
    Base.reg(Data, "gc::Data", Base).constructor = (id) => Data(id);
  }

  Data(id) {
    this.id = id;
  }
  
  static fromByteBuffer(TypedData.ByteBuffer buffer) {
    return BufferData.allocate(buffer);
  }
}

class BufferData extends Data {
  static reg() {
    Base.reg(BufferData, "gc::BufferData", Data)
    ..constructor = (id)=>BufferData(id);
  }

  BufferData(id):super(id);
  BufferData.allocate(TypedData.ByteBuffer buffer):super(null) {

    int length = buffer.lengthInBytes;
    Pointer<Uint8> buf = malloc.allocate(length);
    TypedData.Uint8List buflist = buf.asTypedList(length);
    buflist.setRange(0, length, buffer.asUint8List(0, length).getRange(0, length));

    super.allocate([buf, length, 1]);
    malloc.free(buf);
  }
}