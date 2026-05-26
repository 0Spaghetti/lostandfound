import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;

import '../../data/models.dart';
import '../../shared/l10n/app_strings.dart';
import '../../shared/widgets/common_widgets.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({
    super.key,
    required this.strings,
    required this.repository,
    this.existingPost,
  });

  final AppStrings strings;
  final ItemPostRepository repository;
  final ItemPost? existingPost;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _locationDetailController =
      TextEditingController();

  PostType _type = PostType.lost;
  ItemCategory? _category;
  CampusLocation? _location;
  String? _photoUrl;
  DateTime _reportDateTime = DateTime.now();
  bool _isUrgent = false;
  bool _hasReward = false;
  bool _publishing = false;
  bool _showErrors = false;

  AppStrings get strings => widget.strings;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
    final existing = widget.existingPost;
    if (existing != null) {
      _type = existing.type;
      _category = existing.category;
      _location = existing.location;
      _photoUrl = existing.photoUrl;
      _reportDateTime = existing.dateTime;
      _isUrgent = existing.isUrgent;
      _hasReward = existing.hasReward;
      _titleController.text = existing.title ?? '';
      _descriptionController.text = existing.description;
      _contactController.text = existing.createdBy.contactMethod ?? '';
      _colorController.text = existing.itemColor ?? '';
      _brandController.text = existing.itemBrand ?? '';
      _detailsController.text = existing.distinguishingDetails ?? '';
      _locationDetailController.text = existing.locationDetail ?? '';
    }
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _descriptionController
      ..removeListener(_onTextChanged)
      ..dispose();
    _titleController
      ..removeListener(_onTextChanged)
      ..dispose();
    _contactController.dispose();
    _colorController.dispose();
    _brandController.dispose();
    _detailsController.dispose();
    _locationDetailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoundedSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(strings.camera),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(strings.gallery),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    final picked = await _pickPhotoDataUri(fromCamera: choice == 'camera');
    if (picked == null) return;
    setState(() {
      _photoUrl = picked;
      _showErrors = false;
    });
  }

  Future<String?> _pickPhotoDataUri({required bool fromCamera}) async {
    try {
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final picker = ImagePicker();
        final xFile = await picker.pickImage(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 82,
        );
        if (xFile == null) return null;
        return dataUriFromBytes(await xFile.readAsBytes());
      }

      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final bytes = result.files.single.bytes;
      if (bytes == null) return null;
      return dataUriFromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openLocationPicker() async {
    final picked = await showDialog<CampusLocation>(
      context: context,
      builder: (_) => LocationPickerDialog(strings: strings),
    );

    if (picked != null) {
      setState(() {
        _location = picked;
        _showErrors = false;
      });
    }
  }

  void _useCurrentLocation() {
    setState(() {
      _location = campusLocations.first;
      _showErrors = false;
    });
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatReportDateTimePrimary(AppStrings strings) {
    final dateLabel = DateUtils.isSameDay(_reportDateTime, DateTime.now())
        ? strings.today
        : intl.DateFormat.MMMd(strings.localeName).format(_reportDateTime);
    final timeLabel = intl.DateFormat.jm(
      strings.localeName,
    ).format(_reportDateTime);
    return '$dateLabel, $timeLabel';
  }

  Future<void> _pickReportDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reportDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reportDateTime),
    );
    if (pickedTime == null) return;

    setState(() {
      _reportDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _publish() async {
    final valid = _formKey.currentState?.validate() ?? false;
    final ready =
        valid &&
        _photoUrl != null &&
        _category != null &&
        _location != null &&
        _descriptionController.text.trim().isNotEmpty;

    if (!ready) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.validationError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _publishing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final post = ItemPost(
      id:
          widget.existingPost?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      status: _type == PostType.lost ? PostStatus.lost : PostStatus.found,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category!,
      photoUrl: _photoUrl!,
      location: _location!,
      dateTime: _reportDateTime,
      createdBy: Poster(
        userId: widget.existingPost?.createdBy.userId ?? 'current-user',
        contactMethod: _trimOrNull(_contactController.text),
      ),
      itemColor: _trimOrNull(_colorController.text),
      itemBrand: _trimOrNull(_brandController.text),
      distinguishingDetails: _trimOrNull(_detailsController.text),
      locationDetail: _trimOrNull(_locationDetailController.text),
      hasReward: _type == PostType.lost && _hasReward,
      isUrgent: _type == PostType.lost && _isUrgent,
    );

    if (widget.existingPost == null) {
      await widget.repository.addPost(post);
    } else {
      await widget.repository.updatePost(post);
    }
    if (!mounted) return;

    setState(() => _publishing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existingPost == null
              ? strings.publishSuccess
              : strings.reportUpdated,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = strings.localeName == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final backButton = _TopBarBackButton(
      onPressed: () => Navigator.maybePop(context),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          leadingWidth: 72,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          centerTitle: true,
          leading: Padding(
            padding: EdgeInsetsDirectional.only(start: isArabic ? 18 : 8),
            child: Center(child: isArabic ? const _TopBarLogo() : backButton),
          ),
          title: Text(
            widget.existingPost == null
                ? strings.addReport
                : strings.editReport,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0A2758),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.only(end: isArabic ? 10 : 18),
              child: Center(child: isArabic ? backButton : const _TopBarLogo()),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE4EAF3)),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                _ReportTypeSelector(
                  type: _type,
                  strings: strings,
                  onChanged: (value) => setState(() => _type = value),
                ),
                const SizedBox(height: 14),
                _UploadArea(
                  photoUrl: _photoUrl,
                  hasError: _showErrors && _photoUrl == null,
                  strings: strings,
                  onTap: _pickImage,
                ),
                if (_showErrors && _photoUrl == null)
                  _InlineError(message: strings.requiredField),
                const SizedBox(height: 14),
                _FormRowCard(
                  label: strings.category,
                  child: DropdownButtonFormField<ItemCategory>(
                    initialValue: _category,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                    hint: Text(strings.categorySelectHint),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF12233D),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    items: ItemCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(categoryLabel(category, strings)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                        _showErrors = false;
                      });
                    },
                  ),
                ),
                if (_showErrors && _category == null)
                  _InlineError(message: strings.requiredField),
                const SizedBox(height: 12),
                _FormRowCard(
                  label: strings.reportTitle,
                  child: TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: strings.reportTitleHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF12233D),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ItemAttributesCard(
                  strings: strings,
                  colorController: _colorController,
                  brandController: _brandController,
                  detailsController: _detailsController,
                ),
                if (_type == PostType.lost) ...[
                  const SizedBox(height: 12),
                  _LostOptionsCard(
                    strings: strings,
                    isUrgent: _isUrgent,
                    hasReward: _hasReward,
                    onUrgentChanged: (value) =>
                        setState(() => _isUrgent = value),
                    onRewardChanged: (value) =>
                        setState(() => _hasReward = value),
                  ),
                ],
                const SizedBox(height: 12),
                _FormRowCard(
                  label: strings.dateTime,
                  child: _DateTimeField(
                    value: _formatReportDateTimePrimary(strings),
                    helper: strings.reportDateTimeHint,
                    onTap: _pickReportDateTime,
                  ),
                ),
                const SizedBox(height: 12),
                _FormRowCard(
                  label: strings.contactOptional,
                  child: TextFormField(
                    controller: _contactController,
                    textInputAction: TextInputAction.next,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: strings.contactMethodHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF12233D),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel(strings.itemDescription),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 6,
                        maxLength: 500,
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        decoration: InputDecoration(
                          hintText: strings.itemDescriptionHint,
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF12233D),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return strings.requiredField;
                          if (text.length > 500) {
                            return strings.descriptionTooLong;
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          '${_descriptionController.text.length}/500',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _LocationSection(
                  strings: strings,
                  location: _location,
                  locationDetailController: _locationDetailController,
                  hasError: _showErrors && _location == null,
                  errorMessage: strings.requiredField,
                  onUseCurrentLocation: _useCurrentLocation,
                  preview: _LocationPreview(
                    location: _location ?? campusLocations.first,
                    strings: strings,
                    hasError: _showErrors && _location == null,
                    onTap: _openLocationPicker,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: FilledButton(
              onPressed: _publishing ? null : _publish,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF0A2758),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: _publishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.existingPost == null
                          ? strings.submitReport
                          : strings.saveChanges,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080A2758),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF0A2758),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.centered = false});

  final String message;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: centered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFE9435A),
          size: 14,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFE9435A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 7, start: 4, end: 4),
      child: centered ? Center(child: content) : content,
    );
  }
}

class _TopBarBackButton extends StatelessWidget {
  const _TopBarBackButton({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: const Color(0xFF0A2758),
      iconSize: 22,
      tooltip: tooltip,
    );
  }
}

class _TopBarLogo extends StatelessWidget {
  const _TopBarLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A2758),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: const CollegeLogoAsset(
        fallback: Icon(
          Icons.account_balance_rounded,
          color: Color(0xFF0A2758),
          size: 21,
        ),
      ),
    );
  }
}

class _ReportTypeSelector extends StatelessWidget {
  const _ReportTypeSelector({
    required this.type,
    required this.strings,
    required this.onChanged,
  });

  final PostType type;
  final AppStrings strings;
  final ValueChanged<PostType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReportTypeSegment(
            label: strings.lost,
            dotColor: const Color(0xFFE9435A),
            selected: type == PostType.lost,
            onTap: () => onChanged(PostType.lost),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ReportTypeSegment(
            label: strings.found,
            dotColor: const Color(0xFF15A56E),
            selected: type == PostType.found,
            onTap: () => onChanged(PostType.found),
          ),
        ),
      ],
    );
  }
}

class _ReportTypeSegment extends StatelessWidget {
  const _ReportTypeSegment({
    required this.label,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0A2758) : const Color(0xFFE4EAF3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF0A2758)
                    : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormRowCard extends StatelessWidget {
  const _FormRowCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final field = DefaultTextStyle.merge(
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      child: child,
    );

    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldStack = constraints.maxWidth < 330;
          if (shouldStack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [FieldLabel(label), const SizedBox(height: 8), field],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 92, maxWidth: 128),
                child: FieldLabel(label),
              ),
              const SizedBox(width: 12),
              Expanded(child: field),
            ],
          );
        },
      ),
    );
  }
}

class _ItemAttributesCard extends StatelessWidget {
  const _ItemAttributesCard({
    required this.strings,
    required this.colorController,
    required this.brandController,
    required this.detailsController,
  });

  final AppStrings strings;
  final TextEditingController colorController;
  final TextEditingController brandController;
  final TextEditingController detailsController;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(strings.itemAttributes),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AttributeInputChip(
                icon: Icons.palette_outlined,
                label: strings.itemColor,
                hint: strings.itemColorHint,
                controller: colorController,
              ),
              _AttributeInputChip(
                icon: Icons.sell_outlined,
                label: strings.itemBrand,
                hint: strings.itemBrandHint,
                controller: brandController,
              ),
              _AttributeInputChip(
                icon: Icons.fingerprint_rounded,
                label: strings.distinguishingDetails,
                hint: strings.distinguishingDetailsHint,
                controller: detailsController,
                wide: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttributeInputChip extends StatelessWidget {
  const _AttributeInputChip({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = wide
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return SizedBox(
          width: width.clamp(132.0, constraints.maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4EAF3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0A2758), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      labelStyle: const TextStyle(
                        color: Color(0xFF0A2758),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF12233D),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LostOptionsCard extends StatelessWidget {
  const _LostOptionsCard({
    required this.strings,
    required this.isUrgent,
    required this.hasReward,
    required this.onUrgentChanged,
    required this.onRewardChanged,
  });

  final AppStrings strings;
  final bool isUrgent;
  final bool hasReward;
  final ValueChanged<bool> onUrgentChanged;
  final ValueChanged<bool> onRewardChanged;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(strings.lostOptions),
          const SizedBox(height: 12),
          _ToggleOption(
            icon: Icons.priority_high_rounded,
            title: strings.urgentReport,
            subtitle: strings.urgentReportHint,
            value: isUrgent,
            onChanged: onUrgentChanged,
          ),
          const SizedBox(height: 10),
          _ToggleOption(
            icon: Icons.volunteer_activism_outlined,
            title: strings.rewardOffered,
            subtitle: strings.rewardOfferedHint,
            value: hasReward,
            onChanged: onRewardChanged,
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFF0F6FF) : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? const Color(0xFF0A2758) : const Color(0xFFE4EAF3),
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0A2758), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0A2758),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.value,
    required this.helper,
    required this.onTap,
  });

  final String value;
  final String helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const _DateTimeIconPair(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF12233D),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeIconPair extends StatelessWidget {
  const _DateTimeIconPair();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            child: _DateTimeMiniIcon(icon: Icons.calendar_month_outlined),
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4EAF3)),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF1C63E8),
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeMiniIcon extends StatelessWidget {
  const _DateTimeMiniIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE9FF)),
      ),
      child: Icon(icon, color: const Color(0xFF0A2758), size: 16),
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea({
    required this.photoUrl,
    required this.hasError,
    required this.strings,
    required this.onTap,
  });

  final String? photoUrl;
  final bool hasError;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFE9435A)
        : const Color(0xFFC7D2E2);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: photoUrl == null ? Colors.transparent : borderColor,
            width: 1.2,
          ),
        ),
        child: photoUrl == null
            ? CustomPaint(
                painter: _DashedBorderPainter(color: borderColor, radius: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF0F7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          size: 24,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.tapToUpload,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A2758),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.cameraGalleryHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7B879D),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: PhotoPreview(
                      photoUrl: photoUrl!,
                      category: ItemCategory.other,
                      size: 140,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140A2758),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: onTap,
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: strings.changePhoto,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.strings,
    required this.location,
    required this.locationDetailController,
    required this.hasError,
    required this.errorMessage,
    required this.onUseCurrentLocation,
    required this.preview,
  });

  final AppStrings strings;
  final CampusLocation? location;
  final TextEditingController locationDetailController;
  final bool hasError;
  final String errorMessage;
  final VoidCallback onUseCurrentLocation;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF0A2758),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(child: FieldLabel(strings.location)),
              InkWell(
                onTap: onUseCurrentLocation,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDDE9FF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Color(0xFF0A2758),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        strings.useCurrentGps,
                        style: const TextStyle(
                          color: Color(0xFF0A2758),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          preview,
          const SizedBox(height: 10),
          Text(
            location == null
                ? strings.locationApproxHint
                : campusLocationLabel(location!, strings),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: hasError
                  ? const Color(0xFFE9435A)
                  : const Color(0xFF7B879D),
              fontSize: location == null ? 10 : 11,
              fontWeight: location == null ? FontWeight.w600 : FontWeight.w800,
            ),
          ),
          if (hasError) _InlineError(message: errorMessage, centered: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4EAF3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  color: Color(0xFF0A2758),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: locationDetailController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: strings.locationDetail,
                      hintText: strings.locationDetailHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      labelStyle: const TextStyle(
                        color: Color(0xFF0A2758),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF12233D),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({
    required this.location,
    required this.strings,
    required this.hasError,
    required this.onTap,
  });

  final CampusLocation location;
  final AppStrings strings;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFE9435A)
        : const Color(0xFFE4EAF3);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: CampusMapPainter())),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0x1A1C63E8),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x180A2758),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_pin,
                    color: Color(0xFF0A2758),
                    size: 30,
                  ),
                ),
              ),
              PositionedDirectional(
                top: 10,
                start: 10,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 210),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE4EAF3)),
                  ),
                  child: Text(
                    campusLocationLabel(location, strings),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0A2758),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (hasError)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0x12E9435A),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    const dashWidth = 9.0;
    const dashGap = 6.0;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key, required this.strings});

  final AppStrings strings;

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  CampusLocation? _selected = campusLocations.first;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(strings.pickLocation),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniMapPreview(location: _selected ?? campusLocations.first),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  setState(() => _selected = campusLocations.first),
              icon: const Icon(Icons.my_location_rounded),
              label: Text(strings.useCurrentGps),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            RadioGroup<CampusLocation>(
              groupValue: _selected,
              onChanged: (value) => setState(() => _selected = value),
              child: Column(
                children: campusLocations.map((location) {
                  return RadioListTile<CampusLocation>(
                    value: location,
                    selected: _selected == location,
                    contentPadding: EdgeInsets.zero,
                    title: Text(campusLocationLabel(location, strings)),
                    subtitle: Text(
                      '${location.lat.toStringAsFixed(4)}, ${location.lng.toStringAsFixed(4)}',
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          child: Text(strings.apply),
        ),
      ],
    );
  }
}
