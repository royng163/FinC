import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../helpers/authentication_service.dart';
import '../../models/user_model.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  final AuthenticationService authService = AuthenticationService();

  // void signIn() async {
  //   if (formKey.currentState!.validate()) {
  //     setState(() {
  //       isLoading = true;
  //       errorMessage = null;
  //     });

  //     try {
  //       UserModel? user = await authService.signIn(
  //         email: emailController.text.trim(),
  //         password: passwordController.text.trim(),
  //       );

  //       if (user != null) {
  //         // Navigate to home or dashboard
  //         Navigator.pushReplacementNamed(context, '/home');
  //       }
  //     } catch (e) {
  //       setState(() {
  //         errorMessage = e.toString().replaceFirst('Exception: ', '');
  //       });
  //     } finally {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   }
  // }

  void signInAnonymously() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      UserModel? user = await authService.signInAnonymously();

      if (user != null) {
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sign In'),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: isLoading
                ? CircularProgressIndicator()
                : Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 8,
                        children: [
                          if (errorMessage != null)
                            Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red),
                            ),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text('Sign In'),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text("Don't have an account? Sign Up"),
                          ),
                          ElevatedButton(
                            onPressed: signInAnonymously,
                            child: Text('Skip'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ));
  }
}
