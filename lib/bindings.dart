// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

class JacobiCPP {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  JacobiCPP(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  JacobiCPP.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  Result solveJacobi(
    ffi.Pointer<ffi.Pointer<ffi.Double>> A,
    ffi.Pointer<ffi.Double> b,
    int n,
    double tol,
    int maxIterations,
  ) {
    return _solveJacobi(
      A,
      b,
      n,
      tol,
      maxIterations,
    );
  }

  late final _solveJacobiPtr = _lookup<
      ffi.NativeFunction<
          Result Function(
              ffi.Pointer<ffi.Pointer<ffi.Double>>,
              ffi.Pointer<ffi.Double>,
              ffi.Int,
              ffi.Double,
              ffi.Int)>>('solveJacobi');
  late final _solveJacobi = _solveJacobiPtr.asFunction<
      Result Function(ffi.Pointer<ffi.Pointer<ffi.Double>>,
          ffi.Pointer<ffi.Double>, int, double, int)>();

  void freeResult(
    ffi.Pointer<Result> result,
  ) {
    return _freeResult(
      result,
    );
  }

  late final _freeResultPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Result>)>>(
          'freeResult');
  late final _freeResult =
      _freeResultPtr.asFunction<void Function(ffi.Pointer<Result>)>();
}

final class Result extends ffi.Struct {
  external ffi.Pointer<ffi.Double> xNext;

  @ffi.Int()
  external int n;

  @ffi.Double()
  external double residualNorm;

  @ffi.Double()
  external double norm;
}