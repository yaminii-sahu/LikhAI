import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../widgets/likh_components.dart';
import 'preview_screen.dart';
import 'editor_screen.dart';
import '../models/document_model.dart';

class NewDocumentScreen extends StatefulWidget {
  final String language;

  const NewDocumentScreen({
    super.key,
    required this.language,
  });

  @override
  State<NewDocumentScreen> createState() => _NewDocumentScreenState();
}

class _NewDocumentScreenState extends State<NewDocumentScreen> {
  late String _selectedLanguage;
  final TextEditingController _titleController = TextEditingController();

  final List<String> _supportedFormats = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];
  static const int _maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.language == 'Hindi' ? 'hi' : 'en';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickAndValidateImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (image == null) return;

      // 1. Validate file extension
      final nameLower = image.name.toLowerCase();
      final ext = nameLower.contains('.') ? nameLower.split('.').last : '';
      if (!_supportedFormats.contains(ext) && ext.isNotEmpty) {
        _showErrorDialog(
          AppLocale.text(
            widget.language,
            'Unsupported Image Format',
            'असमर्थित छवि प्रारूप',
          ),
          AppLocale.text(
            widget.language,
            'Please select a JPG, PNG, or WebP image.',
            'कृपया JPG, PNG या WebP प्रारूप की छवि चुनें।',
          ),
        );
        return;
      }

      // 2. Validate file bytes and size
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        _showErrorDialog(
          AppLocale.text(widget.language, 'Empty File', 'खाली फ़ाइल'),
          AppLocale.text(
            widget.language,
            'The selected image is empty or corrupted.',
            'चयनित छवि खाली या दूषित है।',
          ),
        );
        return;
      }

      if (bytes.length > _maxFileSizeBytes) {
        _showErrorDialog(
          AppLocale.text(widget.language, 'File Too Large', 'फ़ाइल बहुत बड़ी है'),
          AppLocale.text(
            widget.language,
            'Image size exceeds 25 MB limit.',
            'छवि का आकार 25 MB सीमा से अधिक है।',
          ),
        );
        return;
      }

      if (!mounted) return;

      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            image: image,
            language: _selectedLanguage,
            documentTitle: title,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        AppLocale.text(widget.language, 'Image Selection Error', 'छवि चयन त्रुटि'),
        e.toString(),
      );
    }
  }

  void _openTextOnlyEditor() {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Note ${DateTime.now().day}/${DateTime.now().month}';

    final emptyDoc = DocumentModel(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      rawText: '',
      cleanedText: '',
      editedText: '',
      language: _selectedLanguage,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      confidence: 1.0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          language: widget.language,
          document: emptyDoc,
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocale.text(widget.language, 'OK', 'ठीक है')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocale.text(widget.language, 'New Document', 'नया दस्तावेज़'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            children: [
              Text(
                AppLocale.text(
                  widget.language,
                  'What would you like\nto digitize today?',
                  'आज आप क्या\nडिजिटल करना चाहते हैं?',
                ),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.25,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocale.text(
                  widget.language,
                  'Capture handwriting or upload an image to begin.',
                  'हस्तलिखित नोट्स कैप्चर करें या छवि अपलोड करें।',
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),

              const SizedBox(height: 24),

              // Title input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocale.text(
                    widget.language,
                    'Document Title (Optional)',
                    'दस्तावेज़ शीर्षक (वैकल्पिक)',
                  ),
                  hintText: 'e.g. Physics Class Notes, Meeting Minutes',
                  prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 18),

              // OCR Language Selection
              LikhCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocale.text(
                              widget.language,
                              'OCR Recognition Language',
                              'OCR पहचान भाषा',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              isDense: true,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDark : AppColors.textLight,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text('English (Default)'),
                                ),
                                DropdownMenuItem(
                                  value: 'hi',
                                  child: Text('हिन्दी (Hindi)'),
                                ),
                                DropdownMenuItem(
                                  value: 'auto',
                                  child: Text('Auto-Detect / मिश्रित'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedLanguage = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Option 1: Camera
              _InputOptionCard(
                icon: Icons.camera_alt_rounded,
                title: AppLocale.text(
                  widget.language,
                  'Scan Handwriting',
                  'हस्तलिखित स्कैन करें',
                ),
                subtitle: AppLocale.text(
                  widget.language,
                  'Take a photo of written paper or notebook',
                  'कागज़ या नोटबुक का फोटो लें',
                ),
                badgeText: 'Camera',
                onTap: () => _pickAndValidateImage(ImageSource.camera),
              ),

              const SizedBox(height: 14),

              // Option 2: Gallery
              _InputOptionCard(
                icon: Icons.photo_library_rounded,
                title: AppLocale.text(
                  widget.language,
                  'Upload Image',
                  'छवि अपलोड करें',
                ),
                subtitle: AppLocale.text(
                  widget.language,
                  'Choose existing photo from your gallery',
                  'गैलरी से मौजूदा फोटो चुनें',
                ),
                badgeText: 'Gallery',
                onTap: () => _pickAndValidateImage(ImageSource.gallery),
              ),

              const SizedBox(height: 14),

              // Option 3: Manual Text Entry
              _InputOptionCard(
                icon: Icons.edit_note_rounded,
                title: AppLocale.text(
                  widget.language,
                  'Manual Text / Note',
                  'मैन्युअल टेक्स्ट / नोट',
                ),
                subtitle: AppLocale.text(
                  widget.language,
                  'Type or paste text directly into the editor',
                  'सीधे संपादक में लिखें या पेस्ट करें',
                ),
                badgeText: 'Direct Edit',
                onTap: _openTextOnlyEditor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  const _InputOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LikhCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    LikhBadge(label: badgeText, fontSize: 10),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            size: 22,
          ),
        ],
      ),
    );
  }
}
