import 'package:flutter/material.dart';

class PriorityPicker extends StatefulWidget {
  final String? initialPriority;
  final ValueChanged<String?> onPrioritySelected;

  const PriorityPicker({
    super.key,
    this.initialPriority,
    required this.onPrioritySelected,
  });

  @override
  State<PriorityPicker> createState() => _PriorityPickerState();
}

class _PriorityPickerState extends State<PriorityPicker> {
  late String? selectedPriority;

  @override
  void initState() {
    super.initState();
    selectedPriority = widget.initialPriority;
  }

  void _updatePriority(String? priority) {
    setState(() {
      selectedPriority = priority;
    });
    widget.onPrioritySelected(priority);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Priority',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPriorityOption('High', Colors.red),
            _buildPriorityOption('Medium', Colors.orange),
            _buildPriorityOption('Low', Colors.green),
            _buildPriorityOption('No Priority', Colors.grey),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String label, Color color) {
    return ListTile(
      leading: Icon(Icons.flag, color: color),
      title: Text('$label Priority'),
      trailing: selectedPriority == label ? const Icon(Icons.check, color: Colors.red) : null,
      onTap: () {
        _updatePriority(label);
      },
    );
  }
}