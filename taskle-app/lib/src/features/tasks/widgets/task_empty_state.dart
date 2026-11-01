import 'package:flutter/material.dart';

class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(
          child: Text(
            'Nenhuma tarefa.\nToque em + para criar.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
