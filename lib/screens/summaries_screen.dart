import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/screens/summary_by_person.dart';
import 'package:weighing_system/screens/summary_custome.dart';
import '../l10n/app_localizations.dart';
import 'package:weighing_system/screens/summary_daily.dart';

class SummariesScreen extends StatefulWidget {
  const SummariesScreen({super.key});

  @override
  State<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends State<SummariesScreen> {
  int topIndex = 0;
  final PageStorageBucket bucket = PageStorageBucket();

  List<NavigationPaneItem> buildPaneItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<NavigationPaneItem> items = [
      PaneItem(
        icon: const SizedBox.shrink(),
        //TODO localize
        title: Text('مخصص'),
        body: SummaryByPerson(),
      ),
      PaneItem(
        icon: const SizedBox.shrink(),
        //TODO localize
        title: Text('شامل'),
        body: SummaryCustom(),
      ),
    ];

    return items;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: bucket,
      child: NavigationView(
        pane: NavigationPane(
          displayMode: PaneDisplayMode.top,
          selected: topIndex,
          onChanged: (int i) => setState(() => topIndex = i),
          items: buildPaneItems(context) as List<NavigationPaneItem>,
        ),
      ),
    );
  }
}
