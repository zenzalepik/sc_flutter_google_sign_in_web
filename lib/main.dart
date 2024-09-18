import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart'; // Untuk menentukan tipe MIME
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/oauth2/v2.dart' as oauth2;
import 'package:cached_network_image/cached_network_image.dart';

const String checkApiUrl = 'https://letter-a.co.id/api/v1/auth/check_data.php';
const String updateApiUrl =
    'https://letter-a.co.id/api/v1/auth/update_user.php';

class ProfilePage extends StatefulWidget {
  final UserProfile userProfile;
  // final String? idUser;
  // final String? emailUser;
  ProfilePage({
    // this.idUser,
    // this.emailUser,
    required this.userProfile,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
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

  Future<void> _inisiasi() async {
    setState(() {
      // _idController.text = '${widget.userProfile.id}';
      _emailController.text = '${widget.userProfile.email}';
    });
    print('${_emailController.text}');
  }

  Future<void> _loadUserProfile() async {
    await _inisiasi();
    setState(() {
      _loading = true;
    });

    try {
      final result = await fetchUserProfile(_emailController.text);

      print('Hasil Load User${result}');
      if (result['status'] == '001') {
        final data = result['data'];
        print('Update data udulu yuk ${result['message']}');
        setState(() {
          _idController.text = '${data['id'] ?? ''}';
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
      } else if (result['status'] == '201') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginBerhasil(),
          ),
        );
        print('kamu sudah terdaftar ${result['message']}');
      } else if (result['status'] == '404') {
        print('server bingung ${result['message']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserFormPage(userProfile: widget.userProfile),
          ),
        );
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

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(result['message'])),
        // );
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

  Future<Map<String, dynamic>> fetchUserProfile(String email) async {
    // Future<Map<String, dynamic>> fetchUserProfile(String id, String email) async {
    final response = await http.get(
      Uri.parse('$checkApiUrl?email=$email'),
      // Uri.parse('$checkApiUrl?id=$id&email=$email'),
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

  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final updates = {
        'fullName': _fullNameController.text,
        //'email': _emailController.text,
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

      await updateUserProfile(
          _emailController.text,
          // await updateUserProfile(_idController.text, _emailController.text,
          updates,
          _webImage,
          _imageFile);
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

  Future<void> updateUserProfile(
      String email,
      // Future<void> updateUserProfile(String id, String email,
      Map<String, dynamic> updates,
      XFile? webImage,
      File? imageFile) async {
    try {
      var uri = Uri.parse(updateApiUrl);
      var request = http.MultipartRequest('POST', uri);

      // Menambahkan field non-file
      // request.fields['id'] = id;
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

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Profile updated successfully')),
          // );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginBerhasil(),
            ),
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

class UserFormPage extends StatefulWidget {
  final UserProfile userProfile;
  // final String? idUser;
  // final String? nameUser;
  // final String? passwordUser;
  UserFormPage(
      {
      // this.idUser,
      // this.nameUser,
      // this.passwordUser,
      required this.userProfile});

  @override
  _UserFormPageState createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _idController.text = '${widget.idUser}';
    // _nameController.text = '${widget.nameUser}';
    // _emailController.text = '${widget.passwordUser}';
    saveUser();
  }

  Future<void> inisiasi() async {
    setState(() {
      _nameController.text = '${widget.userProfile.name}';
      _idController.text =
          '${widget.userProfile.id}'.replaceAll(RegExp(r'[^0-9]'), '');
      _emailController.text = '${widget.userProfile.email}';
    });
    print(
        'check id ${widget.userProfile.id.replaceAll(RegExp(r'[^0-9]'), '')}');
  }

  Future<void> saveUser() async {
    await inisiasi();
    final String id = _idController.text;
    final String name = _nameController.text;
    final String email = _emailController.text;

    final url = Uri.parse('https://letter-a.co.id/api/v1/auth/save_user.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'sub': id,
        'name': name,
        'email': email,
        'role': 'va',
      },
    );

    print('check id $id');
    print('check email $email');
    print('check name $name');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User saved successfully!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userProfile: widget.userProfile),
          ),
        );
      } else {
        print('error save function');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseData['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save user: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TextField(
            //   controller: _idController,
            //   decoration: InputDecoration(labelText: 'ID'),
            // ),
            // TextField(
            //   controller: _nameController,
            //   decoration: InputDecoration(labelText: 'Full Name'),
            // ),
            // TextField(
            //   controller: _emailController,
            //   decoration: InputDecoration(labelText: 'Email'),
            // ),
            // SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: saveUser,
            //   child: Text('Save User'),
            // ),
          ],
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: kIsWeb
      ? '748908392834-mncvork2lrh20bsmsipqfavct17tna2h.apps.googleusercontent.com'
      : null,
);

Future<GoogleSignInAccount?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    return googleUser;
  } catch (e) {
    print('Sign-in failed: $e');
    return null;
  }
}

Future<void> signOut() async {
  await _googleSignIn.signOut();
}

class UserProfile {
  final String name;
  final String email;
  final String photoUrl;
  final String id;

  UserProfile({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.id,
  });
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleSignInAccount? _user;

  Future<void> _handleSignIn() async {
    final user = await signInWithGoogle();
    if (user != null) {
      final authHeaders = await user.authHeaders;
      final accessToken = authHeaders['Authorization']?.split(' ')[1];

      if (accessToken != null) {
        print('Token akses: $accessToken');
        final userProfile = await _fetchUserProfile(accessToken);

        if (userProfile != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(userProfile: userProfile),
            ),
          );
        }
      }

      setState(() {
        _user = user;
      });
    }
  }

  Future<UserProfile?> _fetchUserProfile(String accessToken) async {
    final response = await http.get(
      Uri.parse(
          'https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,photos'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      try {
        print('Data Didapat');
        final userData = jsonDecode(response.body);
        print('Profil pengguna: $userData');

        if (userData['names'] != null &&
            userData['names'].isNotEmpty &&
            userData['emailAddresses'] != null &&
            userData['emailAddresses'].isNotEmpty &&
            userData['photos'] != null &&
            userData['photos'].isNotEmpty) {
          final String name = userData['names'][0]['displayName'];
          final String email = userData['emailAddresses'][0]['value'];
          final String photoUrl = '${userData['photos'][0]['url'] ?? ''}';
          final String id = userData['resourceName'];

          return UserProfile(
            name: name,
            email: email,
            photoUrl: photoUrl,
            id: id,
          );
        } else {
          print('Data profil tidak lengkap');
          return null;
        }
      } catch (e) {
        print('Error parsing user profile data: $e');
        return null;
      }
    } else {
      print('Gagal mendapatkan profil pengguna: ${response.statusCode}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Sign-In Sample'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _handleSignIn,
          child: Text('Sign In with Google'),
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign-In Sample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class LoginBerhasil extends StatefulWidget {
  const LoginBerhasil({super.key});

  @override
  State<LoginBerhasil> createState() => _LoginBerhasilState();
}

class _LoginBerhasilState extends State<LoginBerhasil> {
  @override
  Widget build(BuildContext context) {
    return Text('Login Berhasil');
  }
}
