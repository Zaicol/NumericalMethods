import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'lab2_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'output_page.dart';

void main() {
  runApp(const NumApp());
}

class NumApp extends StatefulWidget {
  const NumApp({super.key});

  @override
  State<NumApp> createState() => _NumAppState();
}

class _NumAppState extends State<NumApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? themeIndex = prefs.getInt('themeMode');

    // Provide a fallback to ThemeMode.system if themeIndex is null
    setState(() {
      _themeMode = themeIndex != null
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system; // Use system as the default fallback
    });
  }

  void _toggleTheme(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = themeMode;
    });
    await prefs.setInt('themeMode', themeMode.index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Метод Якоби',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.grey,
        ),
      ), // Dark theme
      themeMode: _themeMode, // Light, Dark, or System theme
      home: MainScreen(
        onThemeChanged: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode; // Add current theme mode

  const MainScreen(
      {Key? key, required this.onThemeChanged, required this.currentThemeMode})
      : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  final GlobalKey<OutputPageState> _outPageKey = GlobalKey<OutputPageState>();

  @override
  void initState() {
    super.initState();
    // Initialize _pages inside initState, where 'widget' can be accessed
    _pages = [
      JacobiScreen(),
      FiniteElementScreen(outputPageKey: _outPageKey,),
      OutputPage(key: _outPageKey),
      SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        currentThemeMode: widget.currentThemeMode,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Lab 1',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            label: 'Lab 2',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.output),
            label: 'Output'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class JacobiScreen extends StatefulWidget {
  @override
  _JacobiScreenState createState() => _JacobiScreenState();
}

class _JacobiScreenState extends State<JacobiScreen> {
  final TextEditingController _matrixController = TextEditingController();
  final TextEditingController _vectorController = TextEditingController();
  final TextEditingController _toleranceController = TextEditingController();
  final TextEditingController _maxIterationsController =
      TextEditingController();

  String _solution = '';
  List<List<double>> xHistory = [];
  List<double> errorList = [];
  List<List<double>> errorVectors = [];

  // Проверка на диагональное преобладание (условие сходимости)
  bool _isDiagonallyDominant(List<List<double>> A) {
    for (int i = 0; i < A.length; i++) {
      // Число в диагонали должно быть больше суммы модулей остальных чисел
      double rowSum =
          A[i].fold(0.0, (acc, val) => acc + val.abs()) - A[i][i].abs();
      if (A[i][i].abs() > rowSum) {
        return true;
      }
    }
    return false;
  }

  String formatNumber(double value) {
    return value.toStringAsFixed(6).replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '');
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
    errorList.clear();
    xHistory.clear();

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
      errorList.add(norm);
      xHistory.add(List.from(xNext));

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

  // Функция для обработки ввода и вызова метода Якоби
  void _calculateSolution() {
    try {
      List<List<double>> A = _matrixController.text
          .trim()
          .split('\n')
          .map((row) => row.split(' ').map((e) => double.parse(e)).toList())
          .toList();
      List<double> b = _vectorController.text
          .trim()
          .split(' ')
          .map((e) => double.parse(e))
          .toList();

      if (!_isDiagonallyDominant(A)) {
        setState(() {
          _solution = 'Ошибка: Матрица не является диагонально доминирующей';
        });
        return;
      }

      double tol = double.tryParse(_toleranceController.text) ?? 1e-10;
      int maxIterations = int.tryParse(_maxIterationsController.text) ?? 1000;

      Map<String, dynamic> jacobiData = prepareJacobi(A, b);
      List<List<double>> B = jacobiData['B'];
      List<double> d = jacobiData['d'];

      List<dynamic> result =
          jacobiMethodCalc(A, b, B, d, tol: tol, maxIterations: maxIterations);
      calculateErrorVectors(result[0]);

      setState(() {
        _solution =
            'Решение: ${result[0].map((e) => formatNumber(e)).join(', ')}\nНевязка: ${result[1]}\nНорма невязки: ${result[2]}';
      });
    } catch (e) {
      setState(() {
        _solution = 'Ошибка: некорректные данные\n$e';
      });
    }
  }

  void _fillDefaultValues() {
    setState(() {
      _matrixController.text = '4 -1 0 0\n-1 4 -1 0\n0 -1 4 -1\n0 0 -1 3';
      _vectorController.text = '15 10 10 10';
      _toleranceController.text = '1e-10';
      _maxIterationsController.text = '1000';
    });
  }

  void _fillRandomValues() {
    int n = 4;
    Random random = Random();

    List<List<double>> randomMatrix = List.generate(
        n,
        (i) => List.generate(
            n,
            (j) =>
                random.nextDouble() * 20 -
                10 +
                (i == j ? random.nextDouble() * 30 + 10 : 0)));

    List<double> randomVector =
        List.generate(n, (i) => random.nextDouble() * 20 - 10);

    String matrixString = randomMatrix
        .map((row) => row.map((e) => e.toStringAsFixed(2)).join(' '))
        .join('\n');
    String vectorString =
        randomVector.map((e) => e.toStringAsFixed(2)).join(' ');

    setState(() {
      _matrixController.text = matrixString;
      _vectorController.text = vectorString;
    });
  }

  void calculateErrorVectors(List<double> x) {
    errorVectors.clear();

    for (int i = 9; i < xHistory.length; i += 10) {
      List<double> errorVector = List.generate(x.length, (index) {
        return x[index] - xHistory[i][index];
      });
      errorVectors.add(errorVector);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            const Text('Введите толерантность (например, 1e-10):'),
            TextField(
              controller: _toleranceController,
              decoration: const InputDecoration(
                hintText: 'Например: 1e-10',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Введите максимальное число итераций:'),
            TextField(
              controller: _maxIterationsController,
              decoration: const InputDecoration(
                hintText: 'Например: 1000',
              ),
              keyboardType: TextInputType.number,
            ),
            const Text(
              'Введите матрицу A (строки через новую строку, элементы через пробел):',
            ),
            TextField(
              controller: _matrixController,
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Например:\n4 -1 0 0\n-1 4 -1 0\n0 -1 4 -1\n0 0 -1 3',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Введите вектор b (элементы через пробел):'),
            TextField(
              controller: _vectorController,
              decoration: const InputDecoration(
                hintText: 'Например: 15 10 10 10',
              ),
            ),
            const SizedBox(height: 16.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fillDefaultValues,
                  child: const Text('Заполнить значениями по умолчанию'),
                ),
                ElevatedButton(
                  onPressed: _fillRandomValues,
                  child: const Text('Заполнить случайными значениями'),
                ),
                ElevatedButton(
                  onPressed: _calculateSolution,
                  child: const Text('Вычислить решение'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(_solution),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 200, // Ограничиваем высоту графика
              child: errorList.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: true),
                        titlesData: const FlTitlesData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(errorList.length, (index) {
                              return FlSpot(index.toDouble(), errorList[index]);
                            }),
                            isCurved: true,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('Нет данных для графика')),
            ),
            SizedBox(
              height: 200, // Задайте подходящую высоту для списка
              child: SingleChildScrollView(
                child: Column(
                  children: xHistory.asMap().entries.map((entry) {
                    int index = entry.key;
                    List<double> result = entry.value;
                    return ListTile(
                      title: Text(
                          'Итерация ${index + 1}: ${result.map((e) => formatNumber(e)).join(', ')}'),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(
              height: 200, // Задайте подходящую высоту для списка
              child: SingleChildScrollView(
                child: Column(
                  children: errorVectors.asMap().entries.map((entry) {
                    int index = entry.key;
                    List<double> errorVector = entry.value;
                    return ListTile(
                      title: Text(
                        'Ошибка на ${(index + 1) * 10}-й итерации: ${errorVector.map((e) => formatNumber(e)).join(', ')}',
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode; // Add the current theme mode

  const SettingsScreen(
      {super.key,
      required this.onThemeChanged,
      required this.currentThemeMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall, // Updated from headline6 to headlineSmall
            ),
            ListTile(
              title: const Text('Light'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: currentThemeMode, // Use currentThemeMode here
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    onThemeChanged(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: currentThemeMode, // Use currentThemeMode here
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    onThemeChanged(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('System Default'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: currentThemeMode, // Use currentThemeMode here
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    onThemeChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
