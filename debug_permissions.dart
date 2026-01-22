// debug_permissions.dart - Vérificateur de permissions
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDebugger extends StatefulWidget {
  @override
  _PermissionDebuggerState createState() => _PermissionDebuggerState();
}

class _PermissionDebuggerState extends State<PermissionDebugger> {
  Map<String, PermissionStatus> _permissions = {};

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    final permissions = {
      'Microphone': Permission.microphone,
      'Audio': Permission.audio,
      'Storage': Permission.storage,
    };

    Map<String, PermissionStatus> results = {};
    for (var entry in permissions.entries) {
      results[entry.key] = await entry.value.status;
    }

    setState(() => _permissions = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug Permissions')),
      body: Column(
        children: [
          ..._permissions.entries.map((e) => ListTile(
            title: Text(e.key),
            trailing: Icon(
              e.value.isGranted ? Icons.check : Icons.close,
              color: e.value.isGranted ? Colors.green : Colors.red,
            ),
            subtitle: Text(e.value.toString()),
          )),
          ElevatedButton(
            onPressed: () async {
              await Permission.microphone.request();
              _checkAllPermissions();
            },
            child: Text('Demander permissions'),
          ),
        ],
      ),
    );
  }
}
