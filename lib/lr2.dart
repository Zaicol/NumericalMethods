import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:intl/intl.dart';
import 'package:numerical_analysis/somewidgets.dart';

class FiniteElementScreen extends StatefulWidget {
  const FiniteElementScreen({super.key});

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

  void customPrint(String message, Function addToOutputField) {
    addToOutputField(message);
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
    print('b=$b, a=$a, h=$h');
    int n = ((b - a) / h).floor();
    print('n=$n');
    h = (b - a) / n;

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
  List<FlSpot> rPoints_log = [];
  List<FlSpot> rPoints2 = [];

  void calculateSolution() {
    setState(() {
      solutionPoints = [];
      uPoints = [];
      rPoints2 = [];
      h = 1 / sliderValue;
      List<double> Uh = findUh();
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

  List<double> findUh({bool useJacobi = false}) {
    List<List<double>> Ah = calcAh(h);
    List<double> F = calcF(h);
    List<double> uH;
    DateTime currentTime = DateTime.now();
    print('\t${DateFormat.Hms().format(currentTime)} - Solving for h=$h, Jacobi=$useJacobi');
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
    print('\t${DateFormat.Hms().format(currentTime2)} - Solved');
    print('\tTook ${currentTime2.difference(currentTime).inSeconds} seconds');

    return uH;
  }

  double euclideanNorm(List<double> xNew, List<double> x) {
    double sumOfSquares = 0.0;

    for (int i = 0; i < x.length; i++) {
      sumOfSquares += pow(xNew[i] - x[i], 2);
    }

    return sqrt(sumOfSquares);
  }

  void calcRhJacobi() {
    setState(() {
      rPoints = [];
      rPoints_log = [];
      for (int i = 10; i < 251; i += 10) {
        h = 1 / (i as double);
        print('h = 1/$i');
        List<double> uH = [0.0] + findUh(useJacobi: true);
        List<double> uOrig = [];
        for (int i = 0; a + h * (i + 1) < b; i += 1) {
          double x = a + h * i;
          double uValue = u(x);
          uOrig.add(uValue);
        }
        double uNorm = sqrt(h) * euclideanNorm(uOrig, uH);
        double uNormLog = log(uNorm).toDouble() / ln10;
        print('sqrt(h) * |u - uh| = $uNorm\nlog=$uNormLog\n========\n');
        rPoints.add(FlSpot(i as double, uNorm));
        rPoints_log.add(FlSpot(i as double, uNormLog));
      }
    });
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
              const SizedBox(height: 10),
              Text('N = $N'),
              Text('K = $K'),
              Text('Границы:\n\ta = $a\n\tb = $b'),
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
                onChangeEnd: (newValue) {
                  calculateSolution();
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: Math.tex(
                  r'u(x) = \sin\left(\frac{\pi (x - a)}{b - a}\right) + \cos\left(\frac{2\pi (x - a)}{b - a}\right) - 1',
                  textStyle: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 10),
              CustomElevatedButton(
                label: 'Поиск Uh',
                onPressed: calculateSolution,
              ),
              CustomElevatedButton(
                label: 'Поиск Uh (Якоби)',
                onPressed: calcRhJacobi,
              ),
              if (solutionPoints.isNotEmpty && uPoints.isNotEmpty) ...[
                SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LineChart(LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: solutionPoints,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    )),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LineChart(LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: uPoints,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    )),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LineChart(LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: rPoints2,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    )),
                  ),
                ),
              ],
              if (rPoints.isNotEmpty) ...[
                SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LineChart(LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: rPoints,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 2,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    )),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LineChart(LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: rPoints_log,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 2,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    )),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
