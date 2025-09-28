import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../api/api_client.dart';

class SpecialRequestDialog extends StatefulWidget {
  final bool isArabic;

  const SpecialRequestDialog({
    super.key,
    required this.isArabic,
  });

  @override
  State<SpecialRequestDialog> createState() => _SpecialRequestDialogState();
}

class _SpecialRequestDialogState extends State<SpecialRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _externalStoreController = TextEditingController();
  final _productLinkController = TextEditingController();
  final _quotedPriceController = TextEditingController();
  
  final ApiClient _api = ApiClient.instance;
  bool _isLoading = false;
  List<File> _selectedFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _externalStoreController.dispose();
    _productLinkController.dispose();
    _quotedPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.paths.map((path) => File(path!)).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedFiles.length} ${'files_selected'.tr()}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('file_picker_error'.tr() + ': $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert files to MultipartFile
      List<http.MultipartFile>? documents;
      if (_selectedFiles.isNotEmpty) {
        documents = _selectedFiles.map((file) {
          return http.MultipartFile.fromBytes(
            'Documents',
            file.readAsBytesSync(),
            filename: file.path.split('/').last,
          );
        }).toList();
      }

      final response = await _api.createSpecialRequest(
        title: _titleController.text.trim(),
        externalStoreName: _externalStoreController.text.trim(),
        productLink: _productLinkController.text.trim(),
        quotedPrice: double.parse(_quotedPriceController.text),
        documents: documents,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('special_request_submitted'.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('special_request_failed'.tr() + ': $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getFileIcon(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Directionality(
          textDirection: direction,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B82FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'special_request'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name Field
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'product_name'.tr(),
                            hintText: 'enter_product_name'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.shopping_bag),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'product_name_required'.tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // External Store Name Field
                        TextFormField(
                          controller: _externalStoreController,
                          decoration: InputDecoration(
                            labelText: 'external_store_name'.tr(),
                            hintText: 'enter_store_name'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.store),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'store_name_required'.tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Product Link Field
                        TextFormField(
                          controller: _productLinkController,
                          decoration: InputDecoration(
                            labelText: 'product_link'.tr(),
                            hintText: 'enter_product_link'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.link),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'product_link_required'.tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Quoted Price Field
                        TextFormField(
                          controller: _quotedPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'quoted_price'.tr(),
                            hintText: 'enter_price'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                            suffixText: 'currency'.tr(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'price_required'.tr();
                            }
                            if (double.tryParse(value) == null) {
                              return 'invalid_price'.tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Documents Section
                        Text(
                          'documents'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'attach_documents'.tr(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickFiles,
                                icon: const Icon(Icons.add),
                                label: Text('select_files'.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B82FF),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              if (_selectedFiles.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '${_selectedFiles.length} ${'files_selected'.tr()}',
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Show selected files
                                ..._selectedFiles.map((file) => Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getFileIcon(file.path),
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          file.path.split('/').last,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedFiles.remove(file);
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.red[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedFiles.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear_all, size: 16),
                                  label: Text('clear_all_files'.tr()),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B82FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'submit_request'.tr(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
