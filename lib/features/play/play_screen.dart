import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/theme.dart';
import '../../data/level_catalog.dart';
import 'puzzle_card.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.controller.unlockedIndices.indexOf(
      widget.controller.currentIndex,
    ),
  );
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.controller.unlockedIndices;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
          child: Row(
            children: [
              for (var i = 0; i < levels.length; i++)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(
                      right: i == levels.length - 1 ? 0 : 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          widget.controller.progress
                              .forLevel(levels[i].id)
                              .isCompleted
                          ? AppColors.mint
                          : i == widget.controller.currentIndex
                          ? AppColors.violet
                          : AppColors.line,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            scrollDirection: Axis.vertical,
            itemCount: available.length,
            onPageChanged: (page) =>
                widget.controller.changePage(available[page]),
            itemBuilder: (context, page) {
              final index = available[page];
              return PuzzleCard(
                key: ValueKey(levels[index].id),
                controller: widget.controller,
                level: levels[index],
                number: index + 1,
                total: levels.length,
                onNext: () {
                  if (index + 1 < levels.length &&
                      widget.controller.isUnlocked(index + 1)) {
                    _pages.animateToPage(
                      widget.controller.unlockedIndices.indexOf(index + 1),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeInOutCubic,
                    );
                  } else {
                    widget.controller.selectTab(1);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
