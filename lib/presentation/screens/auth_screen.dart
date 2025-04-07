import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/auth_cubit.dart';
import 'package:to_do_list_app/presentation/bloc/cubit/task_cubit.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isReg = true;
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Пожалуйста, введите email';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Пожалуйста, введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Пароль должен содержать буквы и цифры';
    }
    return null;
  }

  bool _validateForm() {
    final emailValidation = _validateEmail(_emailController.text);
    final passwordValidation = _validatePassword(_passwordController.text);

    setState(() {
      _emailError = emailValidation;
      _passwordError = passwordValidation;
    });

    return emailValidation == null && passwordValidation == null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          context.read<TaskCubit>().loadUserTasks();
          context.go('/home');
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<TaskCubit>().loadUserTasks();
                context.go('/home');
              },
            ),
            title: Text(isReg ? 'Авторизация' : 'Регистрация'),
          ),
          body: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is Authenticated && isReg) {
                context.go('/home');
              } else if (state is AuthError) {
                if (mounted) {
                  if (state.message.contains('Неверный пароль')) {
                    setState(() {
                      _passwordController.clear();
                      _passwordError = 'Неверный пароль';
                    });
                  } else if (state.message.contains('Пользователь не найден')) {
                    setState(() {
                      _emailError = 'Пользователь с таким email не найден';
                    });
                  } else if (state.message.contains('Email уже используется')) {
                    setState(() {
                      _emailError = 'Этот email уже зарегистрирован';
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                }
              } else if (state is AuthOperationSuccess) {
                if (!isReg) {
                  if (mounted) {
                    setState(() {
                      isReg = true;
                      _emailController.clear();
                      _passwordController.clear();
                      _emailError = null;
                      _passwordError = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Регистрация успешна! Пожалуйста, войдите.')),
                    );
                  }
                }
              }
            },
            builder: (context, state) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isReg ? 'Вход' : 'Регистрация',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Почта',
                          border: const OutlineInputBorder(),
                          errorText: _emailError,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          setState(() {
                            _emailError = _validateEmail(value);
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          border: const OutlineInputBorder(),
                          errorText: _passwordError,
                          suffixIcon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            )
                        ),
                        
                        onChanged: (value) {
                          setState(() {
                            _passwordError = _validatePassword(value);
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  if (_validateForm()) {
                                    if (isReg) {
                                      context.read<AuthCubit>().signIn(
                                            context,
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                    } else {
                                      context.read<AuthCubit>().signUp(
                                            context,
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                    }
                                  }
                                },
                          child: state is AuthLoading
                              ? const CircularProgressIndicator()
                              : Text(isReg ? 'Войти' : 'Зарегистрироваться'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                setState(() {
                                  isReg = !isReg;
                                  _emailError = null;
                                  _passwordError = null;
                                  _emailController.clear();
                                  _passwordController.clear();
                                });
                              },
                        child: Text(isReg
                            ? 'Еще не зарегистрированы? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти'),
                      ),
                      if (isReg) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  final emailValidation = _validateEmail(_emailController.text);
                                  if (emailValidation == null) {
                                    context
                                        .read<AuthCubit>()
                                        .sendPasswordResetEmail(_emailController.text);
                                  } else {
                                    setState(() {
                                      _emailError = emailValidation;
                                    });
                                  }
                                },
                          child: const Text('Забыли пароль?'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}