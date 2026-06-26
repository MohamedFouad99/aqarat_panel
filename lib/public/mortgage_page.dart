import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../theme/app_theme.dart';
import 'widgets/public_page.dart';

/// حاسبة التمويل العقاري — تقدّر القسط الشهري.
class MortgagePage extends StatefulWidget {
  const MortgagePage({super.key});

  @override
  State<MortgagePage> createState() => _MortgagePageState();
}

class _MortgagePageState extends State<MortgagePage> {
  final _fmt = NumberFormat.decimalPattern('en');

  double _price = 2000000;
  double _downPercent = 20;
  double _years = 20;
  double _rate = 8; // نسبة فائدة سنوية %

  double get _loan => _price * (1 - _downPercent / 100);

  double get _monthly {
    final n = _years * 12;
    final r = _rate / 100 / 12;
    if (n <= 0) return 0;
    if (r == 0) return _loan / n;
    final factor = math.pow(1 + r, n);
    return _loan * r * factor / (factor - 1);
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _monthly;
    final total = monthly * _years * 12;
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calculate, color: AppColors.navy),
                    SizedBox(width: 8),
                    Text('حاسبة التمويل العقاري',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _slider('سعر العقار', '${_fmt.format(_price)} ريال',
                            _price, 200000, 20000000, 100000,
                            (v) => setState(() => _price = v)),
                        _slider(
                            'الدفعة المقدمة',
                            '${_downPercent.round()}%  (${_fmt.format(_price * _downPercent / 100)} ريال)',
                            _downPercent,
                            0,
                            80,
                            1,
                            (v) => setState(() => _downPercent = v)),
                        _slider('مدة التمويل', '${_years.round()} سنة', _years,
                            1, 30, 1, (v) => setState(() => _years = v)),
                        _slider('نسبة الفائدة السنوية', '${_rate.toStringAsFixed(1)}%',
                            _rate, 0, 25, 0.5,
                            (v) => setState(() => _rate = v)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.navyLight]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('القسط الشهري التقديري',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('${_fmt.format(monthly.round())} ريال',
                          style: const TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 34,
                              fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white24, height: 28),
                      _resultRow('مبلغ التمويل', _loan),
                      const SizedBox(height: 6),
                      _resultRow('إجمالي المدفوع', total),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'النتائج تقديرية لأغراض التوضيح فقط، وتختلف حسب جهة التمويل.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, String value, double v, double min, double max,
      double step, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: v.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          activeColor: AppColors.gold,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _resultRow(String label, double value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text('${_fmt.format(value.round())} ريال',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      );
}
