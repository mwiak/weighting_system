// Example of how to integrate the template management into your main dashboard
// Add this to your navigation menu or as a button in your main dashboard

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'template_management_screen.dart';
import '../theme/app_theme.dart';

class PrintTemplateIntegrationExample extends StatelessWidget {
  const PrintTemplateIntegrationExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return fluent.ScaffoldPage(
      header: const fluent.PageHeader(
        title: Text('Print Configuration'),
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
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(fluent.FluentIcons.print, size: 32),
                    SizedBox(height: 8),
                    Text('Manage Print Templates'),
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
                    'Print Template System',
                    style: fluent.FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure print templates for your pre-printed A3 forms:',
                    style: TextStyle(color: AppTheme.secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(fluent.FluentIcons.edit, 'Create custom templates'),
                  _buildFeatureRow(fluent.FluentIcons.move, 'Drag & drop field positioning'),
                  _buildFeatureRow(fluent.FluentIcons.settings, 'Configure fonts and formatting'),
                  _buildFeatureRow(fluent.FluentIcons.save, 'Import/Export templates'),
                  _buildFeatureRow(fluent.FluentIcons.print, 'Test print alignment'),
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
