import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:intl/intl.dart';
import 'package:numerical_analysis/output_page.dart';
import 'package:numerical_analysis/some_widgets.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings.dart';

final nativeLibrary = DynamicLibrary.open('Jacobi.dll'); // Update with the actual path

// Define FFI bindings
typedef SolveJacobiC = Pointer<Result> Function(
    Pointer<Pointer<Double>> A, Pointer<Double> b, Int32 n, Double tol, Int32 maxIterations);
typedef SolveJacobiDart = Pointer<Result> Function(
    Pointer<Pointer<Double>> A, Pointer<Double> b, int n, double tol, int maxIterations);

final solveJacobi = nativeLibrary
    .lookup<NativeFunction<SolveJacobiC>>('solveJacobi')
    .asFunction<SolveJacobiDart>();

typedef FreeResultC = Void Function(Pointer<Result>);
typedef FreeResultDart = void Function(Pointer<Result>);

final freeResult = nativeLibrary
    .lookup<NativeFunction<FreeResultC>>('freeResult')
    .asFunction<FreeResultDart>();

class FiniteElementCPPScreen extends StatefulWidget {
  final GlobalKey<OutputPageState> outputPageKey;

  const FiniteElementCPPScreen({super.key, required this.outputPageKey});

  @override
  FiniteElementCPPScreenState createState() => FiniteElementCPPScreenState();
}

class FiniteElementCPPScreenState extends State<FiniteElementCPPScreen> {
  static const N = 1;
  static const K = 74;

  static final double a = (pi * (N + 10)).floorToDouble();
  static final double b = a + K / 50 + 2;

  static final double p = K * exp(10 * N / K);
  static final double q = N * sin(pow(K, N).toDouble()) + 2 * K;

  double h = 0.05;
  double sliderValue = 20;
  int jacobiStep = 10;
  double jacobiHMax = 10;

  void customPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
    widget.outputPageKey.currentState!.addToOutputField(message);
  }

  double u(double x) {
    double part1 = sin(pi * (x - a) / (b - a));
    double part2 = cos(2 * pi * (x - a) / (b - a));
    return part1 + part2 - 1;
  }

  double du1(double x) {
    double part1 = (pi / (b - a)) * cos(pi * (x - a) / (b - a));
    double part2 = -(2 * pi / (b - a)) * sin(2 * pi * (x - a) / (b - a));
    return part1 + part2;
  }

  double du2(double x) {
    double part1 = -(pow(pi, 2) / pow(b - a, 2)) * sin(pi * (x - a) / (b - a));
    double part2 =
        -(4 * pow(pi, 2) / pow(b - a, 2)) * cos(2 * pi * (x - a) / (b - a));
    return part1 + part2;
  }

  double f(double x) {
    return -p * du2(x) + q * u(x);
  }

  double xi(int i, double h) {
    int n = ((b - a) / h).floor();
    h = (b - a) / n;
    return a + i * h;
  }

  double integrate(Function(double) f, double x1, double x2) {
    double sum = 0.0;
    int n = 100;
    double dx = (x2 - x1) / n;
    for (int i = 0; i < n; i++) {
      sum += f(x1 + i * dx) * dx;
    }
    return sum;
  }

  List<double> calcF(double h) {
    int n = ((b - a) / h).floor();
    h = (b - a) / n;
    List<double> v = List.filled(n - 1, 0.0);

    for (int i = 1; i < n; i++) {
      v[i - 1] = integrate((x) => x * f(x), xi(i - 1, h), xi(i, h)) -
          xi(i - 1, h) * integrate(f, xi(i - 1, h), xi(i, h)) +
          xi(i + 1, h) * integrate(f, xi(i, h), xi(i + 1, h)) -
          integrate((x) => x * f(x), xi(i, h), xi(i + 1, h));
    }

    return v.map((val) => val / (h * h)).toList();
  }

  List<List<double>> calcAh(double h) {
    customPrint('b=$b, a=$a, h=$h');
    int n = ((b - a) / h).floor();
    h = (b - a) / n;
    customPrint('n=$n, h=$h');

    List<List<double>> a_1 =
        List.generate(n - 1, (_) => List.filled(n - 1, 0.0));
    List<List<double>> a_2 =
        List.generate(n - 1, (_) => List.filled(n - 1, 0.0));

    for (int i = 0; i < n - 1; i++) {
      a_1[i][i] = 2;
      a_2[i][i] = 4;
      if (i < n - 2) {
        a_1[i][i + 1] = -1;
        a_1[i + 1][i] = -1;
        a_2[i][i + 1] = 1;
        a_2[i + 1][i] = 1;
      }
    }

    for (int i = 0; i < n - 1; i++) {
      for (int j = 0; j < n - 1; j++) {
        a_1[i][j] = (p / (h * h)) * a_1[i][j];
        a_2[i][j] = (q / 6) * a_2[i][j];
      }
    }

    return List.generate(
        n - 1, (i) => List.generate(n - 1, (j) => a_1[i][j] + a_2[i][j]));
  }

  List<FlSpot> rPoints = [];
  List<FlSpot> rPointsLog = [];

  Future<List<double>> findUh() {
    List<List<double>> Ah = calcAh(h);
    List<double> F = calcF(h);
    List<double> uH = [0.0];

    DateTime currentTime = DateTime.now();
    customPrint(
        '\t${DateFormat.Hms().format(currentTime)} - Solving for h=$h, Jacobi');

    double tol = 1e-10;
    int maxIterations = 1000;

    // Prepare input data for FFI
    final int n = Ah.length;
    final allocator = malloc;

    // Allocate memory for matrix Ah
    customPrint('\tAllocating memory for matrix Ah');
    Pointer<Pointer<Double>> aPtr = allocator.allocate<Pointer<Double>>(n);
    for (int i = 0; i < n; i++) {
      Pointer<Double> rowPtr = allocator.allocate<Double>(n);
      for (int j = 0; j < n; j++) {
        rowPtr[j] = Ah[i][j];
      }
      aPtr[i] = rowPtr;
    }

    // Allocate memory for vector F
    customPrint('\tAllocating memory for vector F');
    Pointer<Double> bPtr;
    customPrint('\tTrying to allocate memory for vector F');
    customPrint('n=$n');
    customPrint('F=${F.join(', ')}');

    try {
      bPtr = allocator.allocate<Double>(n);
      for (int i = 0; i < n; i++) {
        bPtr[i] = F[i];
      }
    } catch (e) {
      allocator.free(aPtr);
      customPrint(e.toString());
      rethrow;
    }

    // Call the native C++ function
    customPrint('\tCalling native C++ function');
    Pointer<Result> resultPtr = solveJacobi(aPtr, bPtr, n, tol, maxIterations);

    // Extract the result from the returned pointer
    List<double> xNext = List.generate(n, (i) => resultPtr.ref.xNext[i]);
    uH = xNext;

    // Free allocated memory
    freeResult(resultPtr);
    for (int i = 0; i < n; i++) {
      allocator.free(aPtr[i]);
    }
    allocator.free(aPtr);
    allocator.free(bPtr);

    // current time
    DateTime currentTime2 = DateTime.now();
    customPrint('\t${DateFormat.Hms().format(currentTime2)} - Solved');
    int secs = currentTime2.difference(currentTime).inSeconds;
    Duration diff = currentTime2.difference(currentTime);
    if (secs > 1) {
      customPrint(
          '\tTook ${diff.inSeconds} seconds');
    } else {
      customPrint(
          '\tTook ${diff.inMilliseconds} milliseconds');
    }

    return Future.value(uH);
  }

  double euclideanNorm(List<double> xNew, List<double> x) {
    double sumOfSquares = 0.0;
    double maxR = 0.0;
    double powX;

    for (int i = 0; i < x.length; i++) {
      powX = pow(xNew[i] - x[i], 2).toDouble();
      sumOfSquares += powX;
      if (powX > maxR) {
        maxR = powX;
      }
    }

    customPrint('max pow = $maxR');

    return sqrt(sumOfSquares);
  }

  Future<void> calculateJacobiSolution() async {
    // Prepare the calculations outside of setState
    List<FlSpot> newRPoints = [];
    List<FlSpot> newRPointsLog = [];

    for (int i = 10; i <= jacobiHMax; i += jacobiStep) {
      h = (1 / i);
      customPrint('h = 1/$i');
      List<double> uH = [0.0] + await findUh();
      List<double> uOrig = [];

      for (int j = 0; a + h * (j + 1) < b; j += 1) {
        double x = a + h * j;
        double uValue = u(x);
        uOrig.add(uValue);
      }

      double uNorm = sqrt(h) * euclideanNorm(uOrig, uH);
      double uNormLog = log(uNorm) / ln10;

      customPrint('sqrt(h) * |u - uh| = $uNorm\nlog=$uNormLog\n\n========\n');

      // Collect results
      newRPoints.add(FlSpot(1/i.toDouble(), uNorm));
      newRPointsLog.add(FlSpot(1/i.toDouble(), uNormLog));
    }

    // Use setState only to update the UI
    setState(() {
      rPoints = newRPoints;
      rPointsLog = newRPointsLog;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Расчёт Якоби завершён"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Метод конечных элементов'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Значения для задачи:'),
              Text('· N = $N'),
              Text('· K = $K'),
              const SizedBox(height: 10),
              Text('Границы:\n· a = $a\n· b = $b'),
              const SizedBox(height: 10),
              Text('jacobiHMax = $jacobiHMax'),
              Slider(
                value: jacobiHMax,
                min: 10,
                max: 1000,
                divisions: (1000 - 10) ~/ 10,
                onChanged: (newValue) {
                  setState(() {
                    jacobiHMax = newValue.toInt() + 0.0;
                  });
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Получаем ширину экрана
                    double screenWidth = constraints.maxWidth;

                    // Рассчитываем размер шрифта, который будет подходить для всей ширины экрана
                    double fontSize =
                        screenWidth / 30; // Например, на 10% от ширины экрана

                    // Ограничиваем размер шрифта минимальным и максимальным значением
                    fontSize = fontSize.clamp(16.0, 40.0);

                    return Math.tex(
                      r'u(x) = \sin\left(\frac{\pi (x - a)}{b - a}\right) + \cos\left(\frac{2\pi (x - a)}{b - a}\right) - 1',
                      textStyle: TextStyle(fontSize: fontSize),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              CustomElevatedButton(
                label: 'Поиск Uh (Якоби)',
                onPressed: () async {
                  await calculateJacobiSolution();
                },
              ),

              if (rPoints.isNotEmpty) ...[
                Center(
                    child: const Text('r(h):',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25))),
                CustomChartWidget(
                  points: rPoints,
                  color: Colors.green,
                  showDots: true,
                ),
                Center(
                    child: const Text('r(h) в логарифмическом масштабе:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25))),
                CustomChartWidget(
                  points: rPointsLog,
                  color: Colors.green,
                  showDots: true,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
