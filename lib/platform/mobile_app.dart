import 'package:flutter/material.dart';
import 'package:nlip_app/api_service.dart';
import 'package:nlip_app/src/rust/api/nlip_api.dart';

class MobileApp extends StatefulWidget {
  const MobileApp({super.key});
  
  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  String _serverUrl = '';
  String _username = '';
  String _token = '';
  String? _selectedSpaceId;
  List<Space> _spaces = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Container();
  }
} 