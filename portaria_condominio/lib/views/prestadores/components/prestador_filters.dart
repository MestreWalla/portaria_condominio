import 'package:flutter/material.dart';
import '../../../localizations/app_localizations.dart';

class PrestadorFilters extends StatelessWidget {
  final String filtroAtual;
  final DateTime? dataSelecionada;
  final Function(String) onFiltroChanged;
  final Function(DateTime?) onDataChanged;

  const PrestadorFilters({
    super.key,
    required this.filtroAtual,
    required this.dataSelecionada,
    required this.onFiltroChanged,
    required this.onDataChanged,
  });

  Future<void> _selecionarData(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (data != null) {
      onDataChanged(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(localizations.translate('filter_all')),
                    selected: filtroAtual == 'todos',
                    onSelected: (selected) {
                      onFiltroChanged('todos');
                      onDataChanged(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(localizations.translate('filter_allowed')),
                    selected: filtroAtual == 'liberados',
                    onSelected: (selected) {
                      onFiltroChanged('liberados');
                      onDataChanged(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(localizations.translate('filter_pending')),
                    selected: filtroAtual == 'pendentes',
                    onSelected: (selected) {
                      onFiltroChanged('pendentes');
                      onDataChanged(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(localizations.translate('filter_by_date')),
                    selected: dataSelecionada != null,
                    onSelected: (selected) => _selecionarData(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
