import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart'; // Untuk menentukan tipe MIME

const String checkApiUrl = 'https://letter-a.co.id/api/v1/auth/check_data.php';
const String updateApiUrl =
    'https://letter-a.co.id/api/v1/auth/update_user.php';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(text: '909097');
  final _emailController = TextEditingController(text: 'uio@d.c');
  final _fullNameController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _ijazahController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedInController = TextEditingController();

  bool _loading = false;
  XFile? _webImage; // For web
  File? _imageFile;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        if (kIsWeb) {
          // For web, we can use the XFile directly and read as bytes
          _webImage = pickedImage;
          pickedImage.readAsBytes().then((bytes) {
            _base64Image = base64Encode(bytes);
          });
        } else {
          // For mobile platforms, use File
          _imageFile = File(pickedImage.path);
          _base64Image = base64Encode(_imageFile!.readAsBytesSync());
        }
      });
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final result =
          await fetchUserProfile(_idController.text, _emailController.text);

      print('>>${result}');
      if (result['status'] == '001') {
        final data = result['data'];
        setState(() {
          _fullNameController.text = '${data['fullName'] ?? ''}';
          _placeOfBirthController.text = '${data['placeOfBirth'] ?? ''}';
          _cityController.text = '${data['city'] ?? ''}';
          _provinceController.text = '${data['province'] ?? ''}';
          _dateOfBirthController.text = '${data['dateOfBirth'] ?? ''}';
          _ijazahController.text = '${data['ijazah'] ?? ''}';
          _whatsappController.text = '${data['whatsapp'] ?? ''}';
          _facebookController.text = '${data['facebook'] ?? ''}';
          _instagramController.text = '${data['instagram'] ?? ''}';
          _linkedInController.text = '${data['linkedIn'] ?? ''}';
        });
      } else {
        final data = result['data'];
        setState(() {
          _fullNameController.text = '${data['fullName'] ?? ''}';
          _placeOfBirthController.text = '${data['placeOfBirth'] ?? ''}';
          _cityController.text = '${data['city'] ?? ''}';
          _provinceController.text = '${data['province'] ?? ''}';
          _dateOfBirthController.text = '${data['dateOfBirth'] ?? ''}';
          _ijazahController.text = '${data['ijazah'] ?? ''}';
          _whatsappController.text = '${data['whatsapp'] ?? ''}';
          _facebookController.text = '${data['facebook'] ?? ''}';
          _instagramController.text = '${data['instagram'] ?? ''}';
          _linkedInController.text = '${data['linkedIn'] ?? ''}';
        });
        print('${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final updates = {
        'fullName': _fullNameController.text,
        'placeOfBirth': _placeOfBirthController.text,
        'city': _cityController.text,
        'province': _provinceController.text,
        'dateOfBirth': _dateOfBirthController.text,
        'ijazah': _ijazahController.text,
        'whatsapp': _whatsappController.text,
        'facebook': _facebookController.text,
        'instagram': _instagramController.text,
        'linkedIn': _linkedInController.text,
      };

      await updateUserProfile(_idController.text, _emailController.text,
          updates, _webImage, _imageFile);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String id, String email) async {
    final response = await http.get(
      Uri.parse('$checkApiUrl?id=$id&email=$email'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> updateUserProfile(String id, String email,
      Map<String, dynamic> updates, XFile? webImage, File? imageFile) async {
    try {
      var uri = Uri.parse(updateApiUrl);
      var request = http.MultipartRequest('POST', uri);

      // Menambahkan field non-file
      request.fields['id'] = id;
      request.fields['email'] = email;

      // Menambahkan field dari updates, memastikan semua nilai adalah string
      updates.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Menambahkan file jika ada
      if (imageFile != null) {
        String mimeType = getMimeType(imageFile.path);
        request.files.add(
          http.MultipartFile(
            'profileImage',
            imageFile.readAsBytes().asStream(),
            imageFile.lengthSync(),
            filename: imageFile.uri.pathSegments.last,
            contentType: MediaType.parse(mimeType),
          ),
        );
      } else if (webImage != null) {
        String mimeType = getMimeType(webImage.name);
        request.files.add(
          http.MultipartFile.fromBytes(
            'profileImage',
            await webImage.readAsBytes(),
            filename: webImage.name,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      // Mengirim permintaan
      var response = await request.send();

      // Mengambil respons dari server
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  String getMimeType(String filename) {
    return lookupMimeType(filename) ?? 'application/octet-stream';
  }

  Widget _buildImageDisplay() {
    if (_base64Image != null) {
      if (kIsWeb && _webImage != null) {
        return Image.memory(
          base64Decode(_base64Image!),
          width: 100,
          height: 100,
        );
      } else if (!kIsWeb && _imageFile != null) {
        return Image.file(
          _imageFile!,
          width: 100,
          height: 100,
        );
      }
    }
    return Text('No image selected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: _buildImageDisplay(),
                    ),
                    SizedBox(height: 16.0),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _idController,
                            decoration: InputDecoration(labelText: 'ID'),
                            enabled: false,
                          ),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(labelText: 'Email'),
                            enabled: false,
                          ),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(labelText: 'Full Name'),
                          ),
                          TextFormField(
                            controller: _placeOfBirthController,
                            decoration:
                                InputDecoration(labelText: 'Place of Birth'),
                          ),
                          TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(labelText: 'City'),
                          ),
                          TextFormField(
                            controller: _provinceController,
                            decoration: InputDecoration(labelText: 'Province'),
                          ),
                          TextFormField(
                            controller: _dateOfBirthController,
                            decoration:
                                InputDecoration(labelText: 'Date of Birth'),
                          ),
                          TextFormField(
                            controller: _ijazahController,
                            decoration: InputDecoration(labelText: 'Ijazah'),
                          ),
                          TextFormField(
                            controller: _whatsappController,
                            decoration: InputDecoration(labelText: 'WhatsApp'),
                          ),
                          TextFormField(
                            controller: _facebookController,
                            decoration: InputDecoration(labelText: 'Facebook'),
                          ),
                          TextFormField(
                            controller: _instagramController,
                            decoration: InputDecoration(labelText: 'Instagram'),
                          ),
                          TextFormField(
                            controller: _linkedInController,
                            decoration: InputDecoration(labelText: 'LinkedIn'),
                          ),
                          SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: _updateProfile,
                            child: Text('Update Profile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
