import 'package:flutter/material.dart';
import '../../helpers/authentication_service.dart';
import '../../models/user_model.dart';

class AccountUpgradePage extends StatefulWidget {
  const AccountUpgradePage({super.key});

  @override
  AccountUpgradePageState createState() => AccountUpgradePageState();
}

class AccountUpgradePageState extends State<AccountUpgradePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final AuthenticationService authService = AuthenticationService();

  void _upgradeAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserModel? user = await authService.linkAnonymousAccount(
          email: _emailController.text.trim(),
        );

        if (user != null) {
          // Navigate to home or dashboard
          if (!mounted) return;
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upgrade Account'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: _isLoading
              ? CircularProgressIndicator()
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        TextFormField(
                          controller: _emailController,
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
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _upgradeAccount,
                          child: Text('Upgrade Account'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
