import 'package:taskle_app/src/common/patterns/state_pattern.dart';
import 'package:taskle_app/src/common/state_management/state_management.dart';
import 'package:taskle_app/src/features/auth/exceptions/auth_exception.dart';
import 'package:taskle_app/src/features/auth/models/auth_model.dart';
import 'package:taskle_app/src/features/auth/routes/auth_routes.dart';
import 'package:taskle_app/src/features/auth/view_models/login_view_model.dart';
import 'package:taskle_app/src/features/tasks/routes/task_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatefulWidget {
  final LoginViewModel loginViewModel;

  const LoginView({super.key, required this.loginViewModel});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.push(AuthRoutes.register),
            child: const Text('Cadastre-se'),
          ),
        ],
      ),
      body: StateConsumerWidget<LoginViewModel, LoginState>(
        viewModel: widget.loginViewModel,
        listener: (context, state) {
          if (state is SuccessState<AuthModel, AuthException>) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login realizado com sucesso!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            context.go(TaskRoutes.tasks);
          }
          if (state is ErrorState<AuthModel, AuthException>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is LoadingState;
          return _buildForm(isLoading: isLoading);
        },
      ),
    );
  }

  Widget _buildForm({required bool isLoading}) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.login_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Bem-vindo de volta',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Entre para continuar',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'Digite seu email',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, insira seu email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Por favor, insira um email válido';
              }
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Senha',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Digite sua senha',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira sua senha';
              }
              if (value.length < 6) {
                return 'A senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      // TODO: Implementar recuperação de senha
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
              child: const Text('Esqueceu a senha?'),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Não tem uma conta? '),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.push(AuthRoutes.register),
                child: const Text(
                  'Cadastre-se',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.loginViewModel.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }
}
