import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_repository.dart';
import '../../data/measurement_unit.dart';

class RecipeFormScreen extends StatefulWidget {
  final AppRepository repository;
  final Recipe? recipe;

  const RecipeFormScreen({super.key, required this.repository, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _DraftIngredient {
  String name;
  double? quantity;
  MeasurementUnit? unit;

  _DraftIngredient({required this.name, this.quantity, this.unit});
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _urlCtrl;

  final List<_DraftIngredient> _ingredients = [];
  List<String> _existingIngredientNames = [];
  bool _loadingIngredients = true;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.recipe?.name ?? '');
    _descCtrl = TextEditingController(text: widget.recipe?.description ?? '');
    _urlCtrl = TextEditingController(text: widget.recipe?.url ?? '');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final allIngredients = await widget.repository.watchAllIngredients().first;
    final names = allIngredients.map((i) => i.name).toList();

    if (_isEditing) {
      final existing =
          await widget.repository.watchIngredientsForRecipe(widget.recipe!.id).first;
      setState(() {
        _existingIngredientNames = names;
        _ingredients.addAll(existing.map((e) => _DraftIngredient(
              name: e.ingredient.name,
              quantity: e.quantity,
              unit: e.unit,
            )));
        _loadingIngredients = false;
      });
    } else {
      setState(() {
        _existingIngredientNames = names;
        _loadingIngredients = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final description =
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    final url = _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim();

    final int recipeId;
    if (_isEditing) {
      await widget.repository.updateRecipe(
        id: widget.recipe!.id,
        name: name,
        description: description,
        url: url,
      );
      recipeId = widget.recipe!.id;
      await widget.repository.removeAllRecipeIngredients(recipeId);
    } else {
      recipeId = await widget.repository.insertRecipe(
        name: name,
        description: description,
        url: url,
      );
    }

    for (final draft in _ingredients) {
      final ingredientId =
          await widget.repository.findOrCreateIngredient(draft.name.trim());
      await widget.repository.addRecipeIngredient(
        recipeId: recipeId,
        ingredientId: ingredientId,
        quantity: draft.quantity,
        unit: draft.unit,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _showAddIngredientDialog() async {
    final draft = await showDialog<_DraftIngredient>(
      context: context,
      builder: (context) => _IngredientDialog(
        existingNames: _existingIngredientNames,
      ),
    );
    if (draft != null) {
      setState(() => _ingredients.add(draft));
    }
  }

  String _formatIngredient(_DraftIngredient d) {
    if (d.quantity == null && d.unit == null) return d.name;
    final qty = d.quantity != null
        ? (d.quantity! % 1 == 0
            ? d.quantity!.toInt().toString()
            : d.quantity!.toString())
        : '';
    final unit = d.unit?.abbreviation ?? '';
    return '$qty${unit.isNotEmpty ? ' $unit' : ''} ${d.name}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Recipe' : 'New Recipe'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Recipe name *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Recipe URL (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _loadingIngredients ? null : _showAddIngredientDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_loadingIngredients)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_ingredients.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No ingredients added yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...List.generate(_ingredients.length, (i) {
                final draft = _ingredients[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restaurant),
                  title: Text(_formatIngredient(draft)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _ingredients.removeAt(i)),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _IngredientDialog extends StatefulWidget {
  final List<String> existingNames;

  const _IngredientDialog({required this.existingNames});

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  MeasurementUnit? _selectedUnit;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = _quantityCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_quantityCtrl.text.trim());
    Navigator.pop(
      context,
      _DraftIngredient(
        name: _nameCtrl.text.trim(),
        quantity: quantity,
        unit: _selectedUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add ingredient'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (value) {
                if (value.text.isEmpty) return const [];
                return widget.existingNames.where(
                  (n) => n.toLowerCase().contains(value.text.toLowerCase()),
                );
              },
              onSelected: (value) => _nameCtrl.text = value,
              fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                // Keep our controller in sync
                ctrl.addListener(() => _nameCtrl.text = ctrl.text);
                return TextFormField(
                  controller: ctrl,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Ingredient name *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required'
                      : null,
                  onFieldSubmitted: (_) => onSubmit(),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<MeasurementUnit>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: MeasurementUnit.values
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text('${u.abbreviation} (${u.name})'),
                            ))
                        .toList(),
                    onChanged: (u) => setState(() => _selectedUnit = u),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
