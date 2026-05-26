import 'app/app.dart' as app;

export 'app/app.dart' hide main;
export 'app/features/add_item/add_item_screen.dart';
export 'app/features/details/item_details_screen.dart';
export 'app/features/home/campus_shell.dart';
export 'app/features/startup/startup_screen.dart';
export 'app/shared/l10n/app_strings.dart';
export 'app/shared/widgets/common_widgets.dart';
export 'app/data/chat_thread_repository.dart';
export 'app/data/models.dart';

void main() => app.main();
