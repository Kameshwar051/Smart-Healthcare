import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Function to generate the next custom UID
  Future<int> _getNextUID() async {
    var docRef = _firestore.collection('metadata').doc('user_count');
    var doc = await docRef.get();

    if (doc.exists && doc.data()!.containsKey('lastUID')) {
      int lastUID = doc['lastUID'];
      await docRef.update({'lastUID': lastUID + 1});
      return lastUID + 1;
    } else {
      await docRef.set({'lastUID': 1});
      return 1;
    }
  }

  // Function to initialize user data in Firestore
  Future<void> _initializeUserData(String userId, int customUID, String name, String email) async {
    await _firestore.collection('users').doc(userId).set({
      'uid': customUID,
      'name': name,
      'email': email,
      'profilePic': '', // Profile picture (can be updated later)
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'chats': {}, // Stores chat history
    });
  }

  // Sign-up function
  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Generate custom UID
      int newUID = await _getNextUID();

      // Initialize user data in Firestore
      await _initializeUserData(uid, newUID, _nameController.text.trim(), _emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account Created Successfully!')),
      );

      // Redirect to Home Page
      Navigator.pushNamed(context, '/home_page');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Something went wrong.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password must be at least 6 characters.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.shade700,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.blueAccent.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "Fill in the details below",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 15),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 15),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value!.length < 6 ? 'Password must be 6+ characters' : null,
              ),
              const SizedBox(height: 15),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirm Password',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.check, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Sign Up Button
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent.shade700,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
