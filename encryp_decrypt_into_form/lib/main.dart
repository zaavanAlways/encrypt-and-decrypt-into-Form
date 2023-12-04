import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

//fungsi main yang menjalankan aplikasi
void main() {
  runApp(const MyApp());
}

//kelas MyApp, merupakan tampilan awal aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInScreen(), //Halaman pertama yang ditampilkan adalah SignInPage
    );
  }
}

//kelas SignUpScreen, tampilan untuk proses pendaftaran
class SignUpScreen extends StatelessWidget {
  //controllers untuk input username dan password
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Logger _logger = Logger(); //untuk logging

  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'), //judul halaman
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            //input field untuk username
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _performSignUp(context); //tombol sign up
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  //fungsi untuk melakukan proses sign up
  void _performSignUp(BuildContext context) {
    try {
      final prefs = SharedPreferences.getInstance();

      _logger.d('Sign up attempt');

      final String username = _usernameController.text;
      final String password = _passwordController.text;

      //memeriksa apakah username atau password kosong sebelum melanjutkan signup
      if (username.isNotEmpty && password.isNotEmpty) {
        final encrypt.Key key = encrypt.Key.fromLength(32);
        final iv = encrypt.IV.fromLength(16);
        final encrypter = encrypt.Encrypter(encrypt.AES(key));
        final encryptedUsername = encrypter.encrypt(username, iv: iv);
        final encryptedPassword = encrypter.encrypt(password, iv: iv);

        _saveEncryptedDataToPrefs(
          prefs,
          encryptedUsername.base64,
          encryptedPassword.base64,
          key.base64,
          iv.base64,
        ).then((_) {
          Navigator.pop(context);
          _logger.d('Sign up success');
        });
      } else {
        _logger.e('Username or Password cannot be empty');
      }
    } catch (e) {
      _logger.e('An eror occured : $e');
    }
  }

  //fungsi untuk menyimpan data terenkripsi ke SharedPreferences
  Future<void> _saveEncryptedDataToPrefs(
    Future<SharedPreferences> prefs,
    String encryptedUsername,
    String encryptedPassword,
    String keyString,
    String ivString,
  ) async {
    final sharedPreferences = await prefs;
    //logging : menyimpan data pengguna ke SharedPreferences
    _logger.d('Saving user data to SharedPreferences');
    await sharedPreferences.setString('username', encryptedUsername);
    await sharedPreferences.setString('password', encryptedPassword);
    await sharedPreferences.setString('key', keyString);
    await sharedPreferences.setString('iv', ivString);
  }
}

//kelas signInScreen, tampilan untuk proses signIn
class SignInScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Logger _logger = Logger(); // untuk logging

  SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'), //judul halaman
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            //input field untuk username
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            //input field untuk password
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            //Tombol Sign in
            ElevatedButton(
              onPressed: () {
                _performSignIn(context);
              },
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 20),
            //Tombol untuk pindah ke halaman pendaftaran
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  //fungsi untuk melakukan proses sign in
  void _performSignIn(BuildContext context) {
    try {
      final prefs = SharedPreferences.getInstance();

      final String username = _usernameController.text;
      final String password = _passwordController.text;
      _logger.d('Sign in attempt');

      if (username.isNotEmpty && password.isNotEmpty) {
        _retrieveAndDecryptDataFromPrefs(prefs).then((data) {
          if (data.isNotEmpty) {
            final decryptedUsername = data['username'];
            final decryptedPassword = data['password'];

            if (username == decryptedUsername &&
                password == decryptedPassword) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              _logger.d('Sign in Success');
            } else {
              _logger.e('Username or Password is incorrect');
            }
          } else {
            _logger.e('No stored credentials found');
          }
        });
      } else {
        _logger.e('Username and Password cannot be empty');
      }
    } catch (e) {
      _logger.e('An eror occured : $e');
    }
  }

  //fungsi untuk mengambil dan mendekripsi data dari SharedPreferences
  Future<Map<String, String>> _retrieveAndDecryptDataFromPrefs(
    Future<SharedPreferences> prefs,
  ) async {
    final sharedPreferences = await prefs;
    final encryptedUsername = sharedPreferences.getString('username') ?? '';
    final encryptedPassword = sharedPreferences.getString('password') ?? '';
    final keyString = sharedPreferences.getString('key') ?? '';
    final ivString = sharedPreferences.getString('iv') ?? '';

    final encrypt.Key key = encrypt.Key.fromBase64(keyString);
    final iv = encrypt.IV.fromBase64(ivString);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decryptedUsername = encrypter.decrypt64(encryptedUsername, iv: iv);
    final decryptedPassword = encrypter.decrypt64(encryptedPassword, iv: iv);

    //mengambil data terdekripsi
    return {'username': decryptedUsername, 'password': decryptedPassword};
  }
}

//kelas  HomeScreen, halaman utama setelah berhasil signIn
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'), //judul halaman
      ),
      body: const Center(
        child: Text('Welcome Sir!'), //pesan selamat datang
      ),
    );
  }
}
