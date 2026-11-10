// import 'dart:io';
// import 'package:adm_rider/core/shared/helpers/location_helper.dart';
// import 'package:adm_rider/core/shared/helpers/validators.dart';
// import 'package:adm_rider/core/shared/styles/app_colors.dart';
// import 'package:adm_rider/core/shared/styles/app_style.dart';
// import 'package:adm_rider/core/shared/widgets/buttons.dart';
// import 'package:adm_rider/core/shared/widgets/custom_text_field.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:geocoding/geocoding.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey1 = GlobalKey<FormState>();
//   final _formKey3 = GlobalKey<FormState>();

//   int _currentStep = 1; // 1, 2, or 3

//   // Step 1 Controllers
//   final _nameController = TextEditingController();
//   final _mobileController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   // Step 2 Images
//   File? _shopPhoto;
//   File? _aadharCard;
//   File? _panCard;
//   File? _cancelledCheque;
//   final ImagePicker _picker = ImagePicker();

//   // Step 3 Controllers
//   final _addressController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _landmarkController = TextEditingController();
//   final _stateController = TextEditingController();
//   final _zipController = TextEditingController();
//   final _countryController = TextEditingController();
//   final _latController = TextEditingController();
//   final _lngController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   bool _isLoadingLocation = false;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _mobileController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _addressController.dispose();
//     _cityController.dispose();
//     _landmarkController.dispose();
//     _stateController.dispose();
//     _zipController.dispose();
//     _countryController.dispose();
//     _latController.dispose();
//     _lngController.dispose();
//     super.dispose();
//   }

//   void _nextStep() {
//     if (_currentStep == 1) {
//       if (_formKey1.currentState!.validate()) {
//         setState(() => _currentStep++);
//       }
//     } else if (_currentStep == 2) {
//       setState(() => _currentStep++);
//     } else {
//       if (_formKey3.currentState!.validate()) {
//         context.pop();
//       }
//     }
//   }

//   void _previousStep() {
//     if (_currentStep > 1) {
//       setState(() => _currentStep--);
//     }
//   }

//   Widget _buildStepIndicator() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 40.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _buildStepCircle(1),
//           _buildStepLine(1),
//           _buildStepCircle(2),
//           _buildStepLine(2),
//           _buildStepCircle(3),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepCircle(int step) {
//     bool isCompleted = _currentStep > step;
//     bool isActive = _currentStep == step;

//     return Container(
//       width: 32,
//       height: 32,
//       decoration: BoxDecoration(
//         color: isCompleted
//             ? Colors.green
//             : isActive
//             ? const Color(0xFF98001F)
//             : Colors.grey.shade300,
//         shape: BoxShape.circle,
//       ),
//       alignment: Alignment.center,
//       child: isCompleted
//           ? const Icon(Icons.check, color: Colors.white, size: 20)
//           : Text(
//               step.toString(),
//               style: TextStyle(
//                 color: (isActive || isCompleted)
//                     ? Colors.white
//                     : Colors.black54,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//     );
//   }

//   Widget _buildStepLine(int step) {
//     bool isCompleted = _currentStep > step;
//     return Expanded(
//       child: Container(
//         height: 2,
//         color: isCompleted ? Colors.green : Colors.grey.shade300,
//       ),
//     );
//   }

//   Widget _buildStep1() {
//     return Form(
//       key: _formKey1,
//       child: Column(
//         children: [
//           CustomTextField(
//             label: 'Seller Name :',
//             hint: 'Enter your name',
//             controller: _nameController,
//             validator: Validator.defaultValidator,
//           ),
//           CustomTextField(
//             label: 'Mobile Number :',
//             hint: 'Enter your mobile number',
//             controller: _mobileController,
//             keyboardType: TextInputType.phone,
//             validator: Validator.phoneValidator,
//             prefixIcon: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Image.asset('assets/png/india.png', width: 24, height: 24),
//                   const SizedBox(width: 8),
//                   const Text(
//                     '+91',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(width: 8),
//                   Container(width: 1, height: 24, color: Colors.grey.shade300),
//                   const SizedBox(width: 8),
//                 ],
//               ),
//             ),
//           ),
//           CustomTextField(
//             label: 'Email Address :',
//             hint: 'Enter your email address',
//             controller: _emailController,
//             keyboardType: TextInputType.emailAddress,
//             validator: Validator.emailValidator,
//           ),
//           CustomTextField(
//             label: 'Password :',
//             hint: 'Enter password',
//             controller: _passwordController,
//             isPassword: true,
//             obscureText: _obscurePassword,
//             validator: Validator.passwordValidator,
//             onToggleVisibility: () {
//               setState(() {
//                 _obscurePassword = !_obscurePassword;
//               });
//             },
//           ),
//           CustomTextField(
//             label: 'Confirm Password :',
//             hint: 'Confirm your password',
//             controller: _confirmPasswordController,
//             isPassword: true,
//             obscureText: _obscureConfirmPassword,
//             validator: (value) => Validator.passwordValidator(
//               value,
//               otherPassword: _passwordController.text,
//             ),
//             onToggleVisibility: () {
//               setState(() {
//                 _obscureConfirmPassword = !_obscureConfirmPassword;
//               });
//             },
//           ),
//           const SizedBox(height: 24),
//           // SecondaryButton(
//           //   text: 'Next',
//           //   onPressed: _nextStep,
//           //   horizontalMargin: 0,
//           // ),
//           AppButton(
//             onPressed: _nextStep,
//             color: ColorName.primarybackground,
//             horizontalMargin: 0,
//             child: Text('Next', style: AppStyle.buttonNextTextStyle),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 "If you have account? ",
//                 style: TextStyle(color: Colors.black54),
//               ),
//               TextButton(
//                 onPressed: () => context.pop(),
//                 child: const Text(
//                   'Login',
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _pickImage(
//     ImageSource source,
//     void Function(File?) onPicked,
//   ) async {
//     try {
//       final pickedFile = await _picker.pickImage(source: source);
//       if (pickedFile != null) {
//         onPicked(File(pickedFile.path));
//       }
//     } catch (e) {
//       debugPrint("Error picking image: $e");
//     }
//   }

//   void _showImageSourceBottomSheet(void Function(File?) onPicked) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Camera'),
//                 onTap: () {
//                   context.pop();
//                   _pickImage(ImageSource.camera, onPicked);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Gallery'),
//                 onTap: () {
//                   context.pop();
//                   _pickImage(ImageSource.gallery, onPicked);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildImageUploadBox(
//     String label,
//     File? imageFile,
//     void Function(File?) onPicked,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 8),
//           GestureDetector(
//             onTap: () => _showImageSourceBottomSheet(onPicked),
//             child: Container(
//               height: 120,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade300),
//                 image: imageFile != null
//                     ? DecorationImage(
//                         image: FileImage(imageFile),
//                         fit: BoxFit.cover,
//                       )
//                     : null,
//               ),
//               child: imageFile == null
//                   ? Center(
//                       child: Icon(
//                         Icons.camera_alt_outlined,
//                         color: Colors.grey.shade400,
//                         size: 40,
//                       ),
//                     )
//                   : null,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStep2() {
//     return Column(
//       children: [
//         _buildImageUploadBox(
//           'Upload Shop Photo :',
//           _shopPhoto,
//           (file) => setState(() => _shopPhoto = file),
//         ),
//         _buildImageUploadBox(
//           'Upload Aadhar Card :',
//           _aadharCard,
//           (file) => setState(() => _aadharCard = file),
//         ),
//         _buildImageUploadBox(
//           'Upload PAN Card :',
//           _panCard,
//           (file) => setState(() => _panCard = file),
//         ),
//         _buildImageUploadBox(
//           'Upload Cancelled Cheque :',
//           _cancelledCheque,
//           (file) => setState(() => _cancelledCheque = file),
//         ),
//         const SizedBox(height: 24),
//         Row(
//           children: [
//             Expanded(
//               child: AppButton(
//                 onPressed: _previousStep,
//                 color: Colors.white,
//                 borderSide: BorderSide(color: ColorName.primarybackground),
//                 child: Text(
//                   'Previous',
//                   style: AppStyle.buttonPreviousTextStyle,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: AppButton(
//                 onPressed: _nextStep,
//                 color: ColorName.primarybackground,
//                 horizontalMargin: 0,
//                 child: Text('Next', style: AppStyle.buttonNextTextStyle),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Future<void> _fetchLocation() async {
//     setState(() {
//       _isLoadingLocation = true;
//     });

//     final result = await LocationHelper.instance.getLocationWithFallback();

//     if (result.isSuccess && result.position != null) {
//       _latController.text = result.position!.latitude.toString();
//       _lngController.text = result.position!.longitude.toString();

//       try {
//         List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
//           result.position!.latitude,
//           result.position!.longitude,
//         );
//         if (placemarks.isNotEmpty) {
//           Placemark place = placemarks.first;
//           _countryController.text = place.country ?? '';
//           _stateController.text = place.administrativeArea ?? '';
//           _cityController.text =
//               place.locality ?? place.subAdministrativeArea ?? '';
//           _zipController.text = place.postalCode ?? '';
//           _addressController.text =
//               '${place.street ?? ''} ${place.subLocality ?? ''}'.trim();
//         }
//       } catch (e) {
//         debugPrint("Error fetching placemark: $e");
//       }
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(result.message ?? 'Failed to get location')),
//         );
//       }
//     }

//     setState(() {
//       _isLoadingLocation = false;
//     });
//   }

//   Widget _buildStep3() {
//     return Form(
//       key: _formKey3,
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: CustomTextField(
//                   label: 'Latitude :',
//                   hint: '',
//                   controller: _latController,
//                   validator: Validator.defaultValidator,
//                   readOnly: true,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: CustomTextField(
//                   label: 'Longitude :',
//                   hint: '',
//                   controller: _lngController,
//                   validator: Validator.defaultValidator,
//                   readOnly: true,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             width: double.infinity,
//             child: OutlinedButton.icon(
//               onPressed: _isLoadingLocation ? null : _fetchLocation,
//               icon: _isLoadingLocation
//                   ? const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.my_location),
//               label: Text(
//                 _isLoadingLocation ? 'Fetching...' : 'Get Current Location',
//               ),
//               style: OutlinedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 foregroundColor: const Color(0xFF98001F),
//                 side: const BorderSide(color: Color(0xFF98001F)),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           CustomTextField(
//             label: 'Address :',
//             hint: 'Enter your address',
//             controller: _addressController,
//             validator: Validator.defaultValidator,
//           ),
//           CustomTextField(
//             label: 'City :',
//             hint: 'Enter your city',
//             controller: _cityController,
//             validator: Validator.defaultValidator,
//           ),
//           CustomTextField(
//             label: 'Landmark :',
//             hint: 'Enter your landmark',
//             controller: _landmarkController,
//           ),
//           CustomTextField(
//             label: 'State :',
//             hint: 'Enter your state',
//             controller: _stateController,
//             validator: Validator.defaultValidator,
//           ),
//           CustomTextField(
//             label: 'Zip code :',
//             hint: 'Enter your pincode',
//             controller: _zipController,
//             keyboardType: TextInputType.number,
//             validator: Validator.defaultValidator,
//           ),
//           CustomTextField(
//             label: 'Country :',
//             hint: 'Enter your country',
//             controller: _countryController,
//             validator: Validator.defaultValidator,
//           ),
//           const SizedBox(height: 24),
//           Row(
//             children: [
//               Expanded(
//                 child: Expanded(
//                   child: AppButton(
//                     onPressed: _previousStep,
//                     borderSide: BorderSide(color: ColorName.primarybackground),
//                     color: ColorName.white,
//                     horizontalMargin: 0,
//                     child: Text(
//                       'Previous',
//                       style: AppStyle.buttonPreviousTextStyle,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Expanded(
//                   child: AppButton(
//                     onPressed: _nextStep,
//                     color: ColorName.primarybackground,
//                     horizontalMargin: 0,
//                     child: Text(
//                       'Register',
//                       style: AppStyle.buttonNextTextStyle,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () {
//             if (_currentStep > 1) {
//               _previousStep();
//             } else {
//               context.pop();
//             }
//           },
//         ),
//         title: const Text(
//           'Create new account',
//           style: TextStyle(
//             color: Colors.black87,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildStepIndicator(),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24.0,
//                   vertical: 8.0,
//                 ),
//                 child: _currentStep == 1
//                     ? _buildStep1()
//                     : _currentStep == 2
//                     ? _buildStep2()
//                     : _buildStep3(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
