import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/album.dart';

/// Pede ao usuário a quantidade de cópias. Retorna `null` se cancelado.
Future<int?> showQuantityDialog(
  BuildContext context, {
  required String code,
  required int current,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _QuantityDialog(code: code, current: current),
  );
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.code, required this.current});

  final String code;
  final int current;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final _controller = TextEditingController(
    text: widget.current.toString(),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text);
    if (value == null || value < 0 || value > StickerEntry.maxQuantity) {
      setState(() => _error = 'Informe de 0 a ${StickerEntry.maxQuantity}.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Quantidade — ${widget.code}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Cópias possuídas',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
