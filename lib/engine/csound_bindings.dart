import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef _Csound = Pointer<Void>;

// C signatures (MYFLT is float on the Csound Android build).
typedef _CreateC = _Csound Function(Pointer<Void>);
typedef _CreateD = _Csound Function(Pointer<Void>);
typedef _StrIntC = Int32 Function(_Csound, Pointer<Utf8>);
typedef _StrIntD = int Function(_Csound, Pointer<Utf8>);
typedef _IntC = Int32 Function(_Csound);
typedef _NoArgIntC = Int32 Function();
typedef _NoArgIntD = int Function();
typedef _IntD = int Function(_Csound);
typedef _VoidC = Void Function(_Csound);
typedef _VoidD = void Function(_Csound);
typedef _TableSetC = Void Function(_Csound, Int32, Int32, Float);
typedef _TableSetD = void Function(_Csound, int, int, double);
typedef _SetChanC = Void Function(_Csound, Pointer<Utf8>, Float);
typedef _SetChanD = void Function(_Csound, Pointer<Utf8>, double);
typedef _GetChanC = Float Function(_Csound, Pointer<Utf8>, Pointer<Int32>);
typedef _GetChanD = double Function(_Csound, Pointer<Utf8>, Pointer<Int32>);
typedef _MsgBufC = Void Function(_Csound, Int32);
typedef _MsgBufD = void Function(_Csound, int);
typedef _FirstMsgC = Pointer<Utf8> Function(_Csound);
typedef _FirstMsgD = Pointer<Utf8> Function(_Csound);

// SWIG/JNI wrappers for the AndroidCsound C++ class. SWIG ignores JNIEnv and
// jclass, so they are passed as null.
typedef _NewAndroidC = Int64 Function(Pointer<Void>, Pointer<Void>, Uint8);
typedef _NewAndroidD = int Function(Pointer<Void>, Pointer<Void>, int);
typedef _GetCsoundC =
    Int64 Function(Pointer<Void>, Pointer<Void>, Int64, Pointer<Void>);
typedef _GetCsoundD =
    int Function(Pointer<Void>, Pointer<Void>, int, Pointer<Void>);
typedef _ObjVoidC =
    Void Function(Pointer<Void>, Pointer<Void>, Int64, Pointer<Void>);
typedef _ObjVoidD =
    void Function(Pointer<Void>, Pointer<Void>, int, Pointer<Void>);
typedef _PauseC =
    Void Function(Pointer<Void>, Pointer<Void>, Int64, Pointer<Void>, Uint8);
typedef _PauseD =
    void Function(Pointer<Void>, Pointer<Void>, int, Pointer<Void>, int);
typedef _DeleteC = Void Function(Pointer<Void>, Pointer<Void>, Int64);
typedef _DeleteD = void Function(Pointer<Void>, Pointer<Void>, int);

/// Thin `dart:ffi` layer over `libcsoundandroid.so`. No logic lives here.
// ignore_for_file: library_private_types_in_public_api
class CsoundBindings {
  final DynamicLibrary _lib;

  late final _CreateD create = _lib.lookupFunction<_CreateC, _CreateD>(
    'csoundCreate',
  );
  late final _StrIntD _setOption = _lib.lookupFunction<_StrIntC, _StrIntD>(
    'csoundSetOption',
  );
  late final _StrIntD _compileOrc = _lib.lookupFunction<_StrIntC, _StrIntD>(
    'csoundCompileOrc',
  );
  late final _IntD start = _lib.lookupFunction<_IntC, _IntD>('csoundStart');
  late final _IntD performKsmps = _lib.lookupFunction<_IntC, _IntD>(
    'csoundPerformKsmps',
  );
  late final _VoidD stop = _lib.lookupFunction<_VoidC, _VoidD>('csoundStop');
  late final _VoidD destroy = _lib.lookupFunction<_VoidC, _VoidD>(
    'csoundDestroy',
  );
  late final _NoArgIntD sizeOfMyflt = _lib
      .lookupFunction<_NoArgIntC, _NoArgIntD>('csoundGetSizeOfMYFLT');
  late final _TableSetD tableSet = _lib.lookupFunction<_TableSetC, _TableSetD>(
    'csoundTableSet',
  );
  late final _SetChanD _setControlChannel = _lib
      .lookupFunction<_SetChanC, _SetChanD>('csoundSetControlChannel');
  late final _GetChanD _getControlChannel = _lib
      .lookupFunction<_GetChanC, _GetChanD>('csoundGetControlChannel');
  late final _MsgBufD createMessageBuffer = _lib
      .lookupFunction<_MsgBufC, _MsgBufD>('csoundCreateMessageBuffer');
  late final _IntD messageCount = _lib.lookupFunction<_IntC, _IntD>(
    'csoundGetMessageCnt',
  );
  late final _FirstMsgD _firstMessage = _lib
      .lookupFunction<_FirstMsgC, _FirstMsgD>('csoundGetFirstMessage');
  late final _VoidD popFirstMessage = _lib.lookupFunction<_VoidC, _VoidD>(
    'csoundPopFirstMessage',
  );

  late final _NewAndroidD _newAndroidCsound = _lib
      .lookupFunction<_NewAndroidC, _NewAndroidD>(
        'Java_csnd6_csndJNI_new_1AndroidCsound_1_1SWIG_10',
      );
  late final _GetCsoundD _getCsound = _lib
      .lookupFunction<_GetCsoundC, _GetCsoundD>(
        'Java_csnd6_csndJNI_Csound_1GetCsound',
      );
  late final _ObjVoidD _setOpenSlCallbacks = _lib
      .lookupFunction<_ObjVoidC, _ObjVoidD>(
        'Java_csnd6_csndJNI_AndroidCsound_1setOpenSlCallbacks',
      );
  late final _PauseD _pause = _lib.lookupFunction<_PauseC, _PauseD>(
    'Java_csnd6_csndJNI_AndroidCsound_1Pause',
  );
  late final _DeleteD _deleteAndroidCsound = _lib
      .lookupFunction<_DeleteC, _DeleteD>(
        'Java_csnd6_csndJNI_delete_1AndroidCsound',
      );

  CsoundBindings(this._lib);

  /// Loads the bundled library (dependencies first so the linker finds them).
  factory CsoundBindings.open() {
    DynamicLibrary.open('libc++_shared.so');
    DynamicLibrary.open('libsndfile.so');
    return CsoundBindings(DynamicLibrary.open('libcsoundandroid.so'));
  }

  // --- AndroidCsound (C++) object: owns a CSOUND* and provides OpenSL audio ---

  /// Returns an opaque AndroidCsound handle.
  int newAndroidCsound({required bool async}) =>
      _newAndroidCsound(nullptr, nullptr, async ? 1 : 0);

  Pointer<Void> csoundOf(int androidHandle) => Pointer<Void>.fromAddress(
    _getCsound(nullptr, nullptr, androidHandle, nullptr),
  );

  void setOpenSlCallbacks(int androidHandle) =>
      _setOpenSlCallbacks(nullptr, nullptr, androidHandle, nullptr);

  void pause(int androidHandle, bool paused) =>
      _pause(nullptr, nullptr, androidHandle, nullptr, paused ? 1 : 0);

  void deleteAndroidCsound(int androidHandle) =>
      _deleteAndroidCsound(nullptr, nullptr, androidHandle);

  // --- C API helpers with string marshalling ---

  int setOption(Pointer<Void> cs, String option) {
    final p = option.toNativeUtf8();
    try {
      return _setOption(cs, p);
    } finally {
      malloc.free(p);
    }
  }

  int compileOrc(Pointer<Void> cs, String orc) {
    final p = orc.toNativeUtf8();
    try {
      return _compileOrc(cs, p);
    } finally {
      malloc.free(p);
    }
  }

  void setControlChannel(Pointer<Void> cs, String name, double value) {
    final p = name.toNativeUtf8();
    try {
      _setControlChannel(cs, p, value);
    } finally {
      malloc.free(p);
    }
  }

  double getControlChannel(Pointer<Void> cs, String name) {
    final p = name.toNativeUtf8();
    final err = malloc<Int32>();
    try {
      return _getControlChannel(cs, p, err);
    } finally {
      malloc.free(p);
      malloc.free(err);
    }
  }

  /// Drains and returns all pending messages (requires [createMessageBuffer]).
  String drainMessages(Pointer<Void> cs) {
    final b = StringBuffer();
    while (messageCount(cs) > 0) {
      b.write(_firstMessage(cs).toDartString());
      popFirstMessage(cs);
    }
    return b.toString();
  }
}
