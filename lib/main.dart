import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adoption & Travel Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PlanManagerScreen(),
    );
  }
}

enum PlanStatus { pending, completed }
enum PlanPriority { low, medium, high }

class Plan {
  String id;
  String name;
  String description;
  DateTime date;
  PlanStatus status;
  PlanPriority priority;

  Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    this.status = PlanStatus.pending,
    this.priority = PlanPriority.medium,
  });
}

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({Key? key}) : super(key: key);

  @override
  _PlanManagerScreenState createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  final List<Plan> _plans = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _selectedDate = DateTime.now();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  PlanPriority _selectedPriority = PlanPriority.medium;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addPlan(String name, String description, PlanPriority priority) {
    if (name.isNotEmpty) {
      setState(() {
        _plans.add(Plan(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          description: description,
          date: _selectedDate,
          priority: priority,
        ));
        _sortPlans();
      });
    }
  }

  void _updatePlan(String id, String name, String description, PlanPriority priority) {
    if (name.isNotEmpty) {
      setState(() {
        final index = _plans.indexWhere((plan) => plan.id == id);
        if (index != -1) {
          _plans[index] = Plan(
            id: id,
            name: name,
            description: description,
            date: _plans[index].date,
            status: _plans[index].status,
            priority: priority,
          );
          _sortPlans();
        }
      });
    }
  }

  void _togglePlanStatus(String id) {
    setState(() {
      final index = _plans.indexWhere((plan) => plan.id == id);
      if (index != -1) {
        _plans[index] = Plan(
          id: id,
          name: _plans[index].name,
          description: _plans[index].description,
          date: _plans[index].date,
          status: _plans[index].status == PlanStatus.pending
              ? PlanStatus.completed
              : PlanStatus.pending,
          priority: _plans[index].priority,
        );
      }
    });
  }

  void _removePlan(String id) {
    setState(() {
      _plans.removeWhere((plan) => plan.id == id);
    });
  }

  void _sortPlans() {
    setState(() {
      _plans.sort((a, b) {
        // First sort by priority (high to low)
        int priorityComparison = b.priority.index.compareTo(a.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        
        // Then sort by date (most recent first)
        return a.date.compareTo(b.date);
      });
    });
  }

  void _showAddPlanDialog() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedPriority = PlanPriority.medium;
    
    showDialog(
      context: context,
      builder: (context) => _buildPlanDialog('Create New Plan', null),
    );
  }

  void _showEditPlanDialog(Plan plan) {
    _nameController.text = plan.name;
    _descriptionController.text = plan.description;
    _selectedPriority = plan.priority;
    
    showDialog(
      context: context,
      builder: (context) => _buildPlanDialog('Edit Plan', plan.id),
    );
  }

  Widget _buildPlanDialog(String title, String? planId) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
                hintText: 'Enter plan name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter plan description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Date: '),
                TextButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Text(
                    DateFormat.yMMMd().format(_selectedDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlanPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
              ),
              onChanged: (PlanPriority? newValue) {
                setState(() {
                  if (newValue != null) {
                    _selectedPriority = newValue;
                  }
                });
              },
              items: PlanPriority.values
                  .map<DropdownMenuItem<PlanPriority>>((PlanPriority priority) {
                String label = '';
                Color color = Colors.grey;
                
                switch (priority) {
                  case PlanPriority.low:
                    label = 'Low';
                    color = Colors.green;
                    break;
                  case PlanPriority.medium:
                    label = 'Medium';
                    color = Colors.orange;
                    break;
                  case PlanPriority.high:
                    label = 'High';
                    color = Colors.red;
                    break;
                }
                
                return DropdownMenuItem<PlanPriority>(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: color, size: 16),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (planId == null) {
              _addPlan(_nameController.text, _descriptionController.text, _selectedPriority);
            } else {
              _updatePlan(planId, _nameController.text, _descriptionController.text, _selectedPriority);
            }
            Navigator.of(context).pop();
          },
          child: Text(planId == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Color _getPriorityColor(PlanPriority priority) {
    switch (priority) {
      case PlanPriority.low:
        return Colors.green;
      case PlanPriority.medium:
        return Colors.orange;
      case PlanPriority.high:
        return Colors.red;
    }
  }

  Color _getStatusColor(PlanStatus status) {
    switch (status) {
      case PlanStatus.pending:
        return Colors.blue.shade100;
      case PlanStatus.completed:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Adoption & Travel Planner'),
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DragTarget<Map<String, dynamic>>(
                    builder: (context, candidateData, rejectedData) {
                      return Center(
                        child: Text(
                          'Drop plans here to schedule for ${DateFormat.yMMMd().format(_selectedDate)}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                    onAccept: (data) {
                      // Handle the dropped plan
                      _nameController.text = data['name'] as String;
                      _descriptionController.text = data['description'] as String;
                      _showAddPlanDialog();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Plan list
          Expanded(
            child: _plans.isEmpty
                ? const Center(
                    child: Text('No plans yet. Add some plans!'),
                  )
                : ListView.builder(
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return _buildPlanItem(plan);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlanDialog,
        child: const Icon(Icons.add),
        tooltip: 'Create Plan',
      ),
      // Draggable plan template
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drag a new plan:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LongPressDraggable<Map<String, dynamic>>(
              data: {
                'name': 'New Plan',
                'description': 'Plan description',
              },
              feedback: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'New Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.drag_indicator),
                    SizedBox(width: 8),
                    Text('Drag to create a new plan'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(Plan plan) {
    return Dismissible(
      key: Key(plan.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as completed/pending
          _togglePlanStatus(plan.id);
          return false;
        } else {
          // Delete confirmation
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Plan'),
              content: const Text('Are you sure you want to delete this plan?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _removePlan(plan.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${plan.name} removed')),
          );
        }
      },
      child: GestureDetector(
        onLongPress: () => _showEditPlanDialog(plan),
        onDoubleTap: () {
          _removePlan(plan.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${plan.name} removed')),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(plan.status),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getPriorityColor(plan.priority),
              width: 2,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPriorityColor(plan.priority),
              child: Text(
                plan.priority.toString().split('.').last[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              plan.name,
              style: TextStyle(
                decoration: plan.status == PlanStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.description),
                const SizedBox(height: 4),
                Text(
                  'Date: ${DateFormat.yMMMd().format(plan.date)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(
              plan.status == PlanStatus.completed
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: plan.status == PlanStatus.completed
                  ? Colors.green
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}