// lib/pages/create_listing_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/marketplace_listing.dart';
import 'package:smart_crop_dryer/services/marketplace_service.dart';
import 'package:smart_crop_dryer/view_models/auth_view_model.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final MarketplaceService _marketplaceService = MarketplaceService();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedImage;
  String _priceUnit = 'per kg';
  bool _isLoading = false;

  final List<String> _priceUnits = [
    'per kg',
    'per bag',
    'per sack',
    'per basin',
    'per piece',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill location with the user's farm location, if they have one
    final user = context.read<AuthViewModel>().user;
    if (user?.farmLocation != null) {
      _locationController.text = user!.farmLocation;
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = bytes;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Add a Photo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageSourceButton(
                          icon: Icons.camera_alt_outlined,
                          label: "Camera",
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildImageSourceButton(
                          icon: Icons.photo_library_outlined,
                          label: "Gallery",
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      _showErrorSnackBar('Please add a photo of your item');
      return;
    }

    final user = context.read<AuthViewModel>().user;
    if (user == null) return;

    if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
      _showErrorSnackBar(
        'Please add a phone number to your profile before posting a listing',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _marketplaceService.uploadListingImage(
        _selectedImage!,
        user.id,
      );

      final listing = MarketplaceListing(
        sellerId: user.id,
        sellerName: user.name,
        sellerPhotoUrl: user.profileImageUrl,
        sellerPhone: user.phoneNumber!,
        itemName: _itemNameController.text.trim(),
        imageUrl: imageUrl,
        price: double.parse(_priceController.text.trim()),
        priceUnit: _priceUnit,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _marketplaceService.createListing(listing);

      if (!mounted) return;

      _showSuccessSnackBar('Listing posted successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to post listing: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Listing",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo picker
              GestureDetector(
                onTap: _showImagePickerModal,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to add a photo",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Item name
              _buildTextField(
                controller: _itemNameController,
                label: "Item Name",
                hint: "e.g. Beans, Maize, Coffee",
                icon: MdiIcons.sprout,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter what you\'re selling';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price + unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _priceController,
                      label: "Price (UGX)",
                      hint: "e.g. 3500",
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a price';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Unit",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _priceUnit,
                              isExpanded: true,
                              items: _priceUnits.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(
                                    unit,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _priceUnit = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location
              _buildTextField(
                controller: _locationController,
                label: "Location",
                hint: "e.g. Nakawa, Kampala",
                icon: MdiIcons.mapMarkerOutline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: "Description (optional)",
                hint: "Any extra details buyers should know",
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
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
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Post Listing",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: maxLines == 1
                ? Icon(icon, color: Colors.grey.shade500, size: 20)
                : null,
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
