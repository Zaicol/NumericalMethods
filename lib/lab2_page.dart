import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:intl/intl.dart';
import 'package:numerical_analysis/output_page.dart';
import 'package:numerical_analysis/some_widgets.dart';

class FiniteElementScreen extends StatefulWidget {
  final GlobalKey<OutputPageState> outputPageKey;

  const FiniteElementScreen({super.key, required this.outputPageKey});

  @override
  FiniteElementScreenState createState() => FiniteElementScreenState();
}

class FiniteElementScreenState extends State<FiniteElementScreen> {
  static const N = 1;
  static const K = 74;

  static final double a = (pi * (N + 10)).floorToDouble();
  static final double b = a + K / 50 + 2;

  static final double p = K * exp(10 * N / K);
  static final double q = N * sin(pow(K, N).toDouble()) + 2 * K;

  double h = 0.05;
  double sliderValue = 20;
  int jacobiStep = 10;
  double jacobiHMax = 100;

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

  Map<String, dynamic> prepareJacobi(List<List<double>> A, List<double> b) {
    int n = A.length;

    List<double> dInv = List.generate(n, (i) => 1 / A[i][i]);
    List<List<double>> R = List.generate(
        n, (i) => List.generate(n, (j) => i != j ? A[i][j] : 0.0));

    List<List<double>> B =
        List.generate(n, (i) => List.generate(n, (j) => -dInv[i] * R[i][j]));

    List<double> d = List.generate(n, (i) => dInv[i] * b[i]);

    return {'B': B, 'd': d};
  }

  List<dynamic> jacobiMethodCalc(List<List<double>> A, List<double> b,
      List<List<double>> B, List<double> d,
      {double tol = 0, int maxIterations = 1000}) {
    int n = B.length;
    List<double> x = List.filled(n, 0.0);
    List<double> xNext = List.filled(n, 0.0);

    for (int k = 0; k < maxIterations; k++) {
      for (int i = 0; i < n; i++) {
        double sum = 0.0;
        for (int j = 0; j < n; j++) {
          sum += B[i][j] * x[j];
        }
        xNext[i] = sum + d[i];
      }

      double norm = 0.0;
      for (int i = 0; i < n; i++) {
        norm = max(norm, (xNext[i] - x[i]).abs());
      }

      if ((norm < tol && tol != 0) || k + 1 == maxIterations) {
        List<double> residual = List.generate(n, (i) {
          double sum = 0.0;
          for (int j = 0; j < n; j++) {
            sum += A[i][j] * xNext[j];
          }
          return sum - b[i];
        });
        double residualNorm =
            sqrt(residual.map((val) => val * val).reduce((a, b) => a + b));

        return [xNext, residual, residualNorm];
      }

      x = List.from(xNext);
    }

    throw Exception('Метод Якоби не сошелся за $maxIterations итераций.');
  }

  double norm(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }

  List<double> solveLinearSystem(List<List<double>> A, List<double> b) {
    int n = A.length;

    // Augment matrix A with vector b
    List<List<double>> augmentedMatrix =
        List.generate(n, (i) => [...A[i], b[i]]);

    // Forward elimination
    for (int i = 0; i < n; i++) {
      // Make the diagonal element 1 and adjust the rest of the row
      double diagValue = augmentedMatrix[i][i];
      for (int j = 0; j <= n; j++) {
        augmentedMatrix[i][j] /= diagValue;
      }

      // Eliminate column below
      for (int k = i + 1; k < n; k++) {
        double factor = augmentedMatrix[k][i];
        for (int j = 0; j <= n; j++) {
          augmentedMatrix[k][j] -= factor * augmentedMatrix[i][j];
        }
      }
    }

    // Back substitution
    List<double> x = List.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      x[i] = augmentedMatrix[i][n];
      for (int j = i + 1; j < n; j++) {
        x[i] -= augmentedMatrix[i][j] * x[j];
      }
    }

    return x;
  }

  List<FlSpot> solutionPoints = [];
  List<FlSpot> uPoints = [];
  List<FlSpot> rPoints = [];
  List<FlSpot> rPointsLog = [];
  List<FlSpot> rPoints2 = [];

  Future<void> calculateSolution() async {
    customPrint('Calculating solution for h = 1/$sliderValue');
    h = 1 / sliderValue;
    List<double> Uh = await findUh();
    setState(() {
      h = 1 / sliderValue;
      solutionPoints = [];
      uPoints = [];
      rPoints2 = [];
      for (int i = 0; a + h * (i + 1) < b; i += 1) {
        double x = a + h * i;
        double solutionValue = 0;
        if (0 < i && i - 1 < Uh.length) {
          solutionValue = Uh[i - 1];
        }
        double uValue = u(x);
        solutionPoints.add(FlSpot(x, solutionValue));
        uPoints.add(FlSpot(x, uValue));
        rPoints2.add(FlSpot(x, uValue - solutionValue));
      }
    });
  }

  Future<List<double>> findUh({bool useJacobi = false}) {
    List<List<double>> Ah = calcAh(h);
    List<double> F = calcF(h);
    List<double> uH;
    DateTime currentTime = DateTime.now();
    customPrint(
        '\t${DateFormat.Hms().format(currentTime)} - Solving for h=$h, Jacobi=$useJacobi');
    if (useJacobi) {
      double tol = 1e-10;
      int maxIterations = 1000;
      Map<String, dynamic> jacobiData = prepareJacobi(Ah, F);
      List<List<double>> B = jacobiData['B'];
      List<double> d = jacobiData['d'];

      List<dynamic> result =
          jacobiMethodCalc(Ah, F, B, d, tol: tol, maxIterations: maxIterations);
      uH = result[0];
    } else {
      uH = solveLinearSystem(Ah, F);
    }
    // current time
    DateTime currentTime2 = DateTime.now();
    customPrint('\t${DateFormat.Hms().format(currentTime2)} - Solved');
    int secs = currentTime2.difference(currentTime).inSeconds;
    if (secs > 1) {
      customPrint(
          '\tTook ${currentTime2.difference(currentTime).inSeconds} seconds');
    } else {
      customPrint(
          '\tTook ${currentTime2.difference(currentTime).inMilliseconds} milliseconds');
    }

    return Future.value(uH);
  }

  double euclideanNorm(List<double> xNew, List<double> x) {
    double sumOfSquares = 0.0;

    for (int i = 0; i < x.length; i++) {
      sumOfSquares += pow(xNew[i] - x[i], 2);
    }

    return sqrt(sumOfSquares);
  }

  Future<void> calcRhJacobi() async {
    // Prepare the calculations outside of setState
    List<FlSpot> newRPoints = [];
    List<FlSpot> newRPointsLog = [];

    for (int i = 10; i <= jacobiHMax; i += jacobiStep) {
      h = (1 / i);
      customPrint('h = 1/$i');
      List<double> uH = [0.0] + await findUh(useJacobi: true);
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
      newRPoints.add(FlSpot(i.toDouble(), uNorm));
      newRPointsLog.add(FlSpot(i.toDouble(), uNormLog));
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
              Text('h = 1/$sliderValue = $h'),
              Slider(
                value: sliderValue,
                min: 1,
                max: 1000,
                divisions: 100,
                onChanged: (newValue) {
                  setState(() {
                    sliderValue = newValue.toInt() + 0.0;
                    h = 1 / sliderValue;
                  });
                },
                onChangeEnd: (newValue) async {
                  await calculateSolution();
                },
              ),
              Text('jacobiHMax = $jacobiHMax'),
              Slider(
                value: jacobiHMax,
                min: 100,
                max: 1000,
                divisions: (1000 - 100) ~/ 50,
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
                label: 'Поиск Uh',
                onPressed: () async {
                  await calculateSolution();
                },
              ),
              CustomElevatedButton(
                label: 'Поиск Uh (Якоби)',
                onPressed: () async {
                  await calcRhJacobi();
                },
              ),
              if (solutionPoints.isNotEmpty && uPoints.isNotEmpty) ...[
                Center(
                    child: const Text('Оригинальная функция U:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25))),
                CustomChartWidget(
                  points: uPoints,
                  color: Colors.blue,
                ),
                Center(
                    child: const Text('Найденная Uh:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25))),
                CustomChartWidget(
                  points: solutionPoints,
                  color: Colors.lightBlueAccent,
                ),
                Center(
                    child: const Text('Разница:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25))),
                CustomChartWidget(
                  points: rPoints2,
                  color: Colors.red,
                ),
              ],
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
