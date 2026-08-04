import 'package:flutter/material.dart';

/// Messenger global estável — para SnackBars (ex.: "Desfazer") aparecerem e
/// sumirem corretamente, independentemente de rebuilds/tela.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
