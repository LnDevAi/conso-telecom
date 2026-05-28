import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class OperatorSetupPage extends StatelessWidget {
  const OperatorSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Opérateurs & SIM')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Configuration SIM 1',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _SimCard(simSlot: 0),
          const SizedBox(height: 20),
          Text(
            'Configuration SIM 2',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _SimCard(simSlot: 1),
        ],
      ),
    );
  }
}

class _SimCard extends StatefulWidget {
  const _SimCard({required this.simSlot});

  final int simSlot;

  @override
  State<_SimCard> createState() => _SimCardState();
}

class _SimCardState extends State<_SimCard> {
  String _operatorId = 'orange_bf';

  final _operators = [
    {'id': 'orange_bf', 'name': 'Orange Burkina Faso'},
    {'id': 'telecel_bf', 'name': 'Telecel Burkina Faso'},
    {'id': 'moov_bf', 'name': 'Moov Africa Burkina'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sim_card, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'SIM ${widget.simSlot + 1}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _operatorId,
            decoration: const InputDecoration(labelText: 'Opérateur'),
            items: _operators
                .map((o) => DropdownMenuItem(value: o['id'], child: Text(o['name']!)))
                .toList(),
            onChanged: (v) => setState(() => _operatorId = v!),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.dialpad, size: 16),
              label: const Text('Tester USSD balance'),
            ),
          ),
        ],
      ),
    );
  }
}
