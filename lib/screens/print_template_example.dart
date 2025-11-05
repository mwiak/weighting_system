// Example of how to integrate the template management into your main dashboard
// Add this to your navigation menu or as a button in your main dashboard

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../l10n/app_localizations.dart';
import 'template_management_screen.dart';
import '../theme/app_theme.dart';

class PrintTemplateIntegrationExample extends StatelessWidget {
  const PrintTemplateIntegrationExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: Text(l10n.printConfiguration),
      ),
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Button to open template management
            fluent.FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  fluent.FluentPageRoute(
                    builder: (context) => const TemplateManagementScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(fluent.FluentIcons.print, size: 32),
                    const SizedBox(height: 8),
                    Text(l10n.managePrintTemplates),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Information card
            Container(
              width: 400,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: WeighingTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.printTemplateSystem,
                    style: fluent.FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.configureTemplatesDescription,
                    style: const TextStyle(color: AppTheme.secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                      fluent.FluentIcons.edit, l10n.createCustomTemplates),
                  _buildFeatureRow(
                      fluent.FluentIcons.move, l10n.dragDropFieldPositioning),
                  _buildFeatureRow(fluent.FluentIcons.settings,
                      l10n.configureFontsFormatting),
                  _buildFeatureRow(
                      fluent.FluentIcons.save, l10n.importExportTemplates),
                  _buildFeatureRow(
                      fluent.FluentIcons.print, l10n.testPrintAlignment),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// Add this to your main navigation in main_dashboard.dart:
/*
NavigationPaneItem(
  icon: const Icon(fluent.FluentIcons.print),
  title: const Text('Print Templates'),
  body: const TemplateManagementScreen(),
),
*/

// Or add a button in your order management screen to print with template:
/*
fluent.Button(
  child: const Text('Print with Template'),
  onPressed: () async {
    final templateService = TemplatePrintService();
    await templateService.printWeighingTicketTemplate(
      order: selectedOrder,
      client: selectedClient,
      material: selectedMaterial,
      preview: true, // Set to false for direct printing
    );
  },
),
*/
