import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/geometry/scene.dart';
import '../../core/theme.dart';
import '../../models/puzzle_state.dart';
import '../../widgets/geometry_board.dart';

/// Shared puzzle chrome (condition, checks, hints, retry) lives in PuzzleCard.
class RotatePuzzle extends StatelessWidget {
  const RotatePuzzle({
    super.key,
    required this.state,
    required this.height,
    required this.onChanged,
    required this.onRotate,
  });
  final PuzzleState state;
  final double height;
  final ValueChanged<GeometryScene> onChanged;
  final ValueChanged<double> onRotate;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: height,
        child: GeometryBoard(
          key: const ValueKey('angle-board'),
          scene: state.scene,
          complete: state.isComplete,
          onChanged: onChanged,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            const Text(
              'ТВОЙ УГОЛ',
              style: TextStyle(color: AppColors.muted, fontSize: 10),
            ),
            const Spacer(),
            Text(
              '${state.angle.toStringAsFixed(1)}°',
              key: const ValueKey('current-angle'),
              style: const TextStyle(color: AppColors.violet, fontSize: 16),
            ),
          ],
        ),
      ),
      Slider(
        key: const ValueKey('angle-slider'),
        value: math.min(state.angle, 359.9),
        min: 0,
        max: 359.9,
        divisions: 3599,
        semanticFormatterCallback: (v) => '${v.toStringAsFixed(1)} градуса',
        onChanged: state.isComplete ? null : onRotate,
      ),
    ],
  );
}

class DragPuzzle extends StatelessWidget {
  const DragPuzzle({
    super.key,
    required this.state,
    required this.height,
    required this.onChanged,
  });
  final PuzzleState state;
  final double height;
  final ValueChanged<GeometryScene> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: GeometryBoard(
      key: const ValueKey('drag-board'),
      scene: state.scene,
      complete: state.isComplete,
      onChanged: onChanged,
    ),
  );
}

class AnswerPuzzle extends StatefulWidget {
  const AnswerPuzzle({
    super.key,
    required this.state,
    required this.height,
    required this.onChanged,
    required this.onSubmit,
    required this.answerLabel,
  });
  final PuzzleState state;
  final double height;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final String answerLabel;
  @override
  State<AnswerPuzzle> createState() => _AnswerPuzzleState();
}

class _AnswerPuzzleState extends State<AnswerPuzzle> {
  late final TextEditingController _input = TextEditingController(
    text: widget.state.answer,
  );
  @override
  void didUpdateWidget(AnswerPuzzle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_input.text != widget.state.answer) _input.text = widget.state.answer;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: widget.height,
        child: GeometryBoard(
          key: const ValueKey('answer-board'),
          scene: widget.state.scene,
          complete: widget.state.isComplete,
          onChanged: (_) {},
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: TextField(
          key: const ValueKey('numeric-answer'),
          controller: _input,
          enabled: !widget.state.isComplete,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: widget.answerLabel,
            hintText: 'Введи число',
            border: const OutlineInputBorder(),
          ),
          onChanged: widget.onChanged,
          onSubmitted: (_) {
            FocusScope.of(context).unfocus();
            widget.onSubmit();
          },
        ),
      ),
    ],
  );
}
