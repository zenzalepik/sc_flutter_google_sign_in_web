import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/oauth2/v2.dart' as oauth2;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';

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
        print('>>>>>>>>>>>>>>>>Berhasil');
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

class ProfilePage extends StatefulWidget {
  final UserProfile userProfile;

  ProfilePage({required this.userProfile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${widget.userProfile.name}'),
            Text('Url profil ${widget.userProfile.photoUrl}'),
            Image.network(
                'https://cors-anywhere.herokuapp.com/https://lh3.googleusercontent.com/a/ACg8ocIv8WEwq8aeeB2ePArx57fRgs_jzb6V-6GZQ38qzNYoxQqVuBs=s100'),
            Image.network(
              '${widget.userProfile.photoUrl}',
              width: 80,
              height: 80,
            ),
            CachedNetworkImage(
              imageUrl:
                  'https://lh3.googleusercontent.com/a/ACg8ocIv8WEwq8aeeB2ePArx57fRgs_jzb6V-6GZQ38qzNYoxQqVuBs=s100',
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            Text('Email: ${widget.userProfile.email}'),
            Text('ID Pengguna: ${widget.userProfile.id}'),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back'),
            ),
          ],
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
