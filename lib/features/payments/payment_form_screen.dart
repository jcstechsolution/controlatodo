import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_categories.dart';
import '../../core/constants/payment_enums.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/settings_provider.dart';

/// Formulario para crear o editar un pago. Si [existingPayment] no es nulo,
/// la pantalla funciona en modo edición.
class PaymentFormScreen extends StatefulWidget {
  final Payment? existingPayment;

  /// Valores detectados automáticamente por el escáner OCR de facturas
  /// (solo aplican cuando se crea un pago nuevo, no al editar uno existente).
  final String? initialName;
  final double? initialAmount;

  const PaymentFormScreen({
    super.key,
    this.existingPayment,
    this.initialName,
    this.initialAmount,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late PaymentCategory _category;
  late AppCurrency _currency;
  DateTime? _dueDate;
  bool _isRecurring = false;
  late PaymentFrequency _frequency;
  late ReminderOption _reminder;
  bool _isSaving = false;

  bool get _isEditing => widget.existingPayment != null;

  bool get _isFromScanner =>
      !_isEditing && (widget.initialName != null || widget.initialAmount != null);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPayment;
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = existing.amount.toStringAsFixed(
        existing.currency == 'USD' ? 2 : 0,
      );
      _notesController.text = existing.notes ?? '';
      _category = existing.categoryEnum;
      _currency = AppCurrencyX.fromCode(existing.currency);
      _dueDate = existing.dueDate;
      _isRecurring = existing.isRecurring;
      _frequency = existing.frequencyEnum;
      _reminder = ReminderOptionX.fromDays(existing.reminderDays);
    } else {
      _category = PaymentCategory.servicios;
      _currency = AppCurrencyX.fromCode(
        context.read<SettingsProvider>().settings.currency,
      );
      _dueDate = null;
      _isRecurring = false;
      _frequency = PaymentFrequency.mensual;
      _reminder = ReminderOption.oneDayBefore;

      if (widget.initialName != null) {
        _nameController.text = widget.initialName!;
      }
      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(
          _currency.code == 'USD' ? 2 : 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState!.validate();
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de vencimiento.')),
      );
      return;
    }
    if (!isFormValid) return;

    final auth = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    bool success;

    if (_isEditing) {
      final updated = widget.existingPayment!.copyWith(
        name: _nameController.text.trim(),
        category: _category.id,
        amount: amount,
        currency: _currency.code,
        dueDate: _dueDate,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency.id : PaymentFrequency.unaVez.id,
        reminderDays: _reminder.days,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      success = await paymentProvider.updatePayment(uid, updated);
    } else {
      success = await paymentProvider.addPayment(
        uid: uid,
        isPremium: auth.userModel?.isPremium ?? false,
        name: _nameController.text,
        category: _category.id,
        amount: amount,
        currency: _currency.code,
        dueDate: _dueDate!,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency.id : PaymentFrequency.unaVez.id,
        reminderDays: _reminder.days,
        notes: _notesController.text,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
    } else if (paymentProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(paymentProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar pago' : 'Agregar pago'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isFromScanner) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.document_scanner_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Detectado automáticamente desde la foto. '
                            'Revisa los datos antes de guardar.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ejemplo: Internet',
                  ),
                  validator: Validators.paymentName,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentCategory>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: PaymentCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          hintText: '25000',
                        ),
                        validator: Validators.amount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<AppCurrency>(
                        value: _currency,
                        decoration: const InputDecoration(labelText: 'Moneda'),
                        items: AppCurrency.values
                            .map((c) => DropdownMenuItem(value: c, child: Text(c.code)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _currency = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de vencimiento',
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _dueDate == null
                              ? 'DD/MM/AAAA'
                              : '${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('¿Es recurrente?'),
                  value: _isRecurring,
                  onChanged: (value) => setState(() => _isRecurring = value),
                ),
                if (_isRecurring) ...[
                  DropdownButtonFormField<PaymentFrequency>(
                    value: _frequency,
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                    items: PaymentFrequency.values
                        .where((f) => f != PaymentFrequency.unaVez)
                        .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _frequency = value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<ReminderOption>(
                  value: _reminder,
                  decoration: const InputDecoration(labelText: 'Recordarme'),
                  items: ReminderOption.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _reminder = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isEditing ? 'Guardar cambios' : 'Guardar pago',
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
