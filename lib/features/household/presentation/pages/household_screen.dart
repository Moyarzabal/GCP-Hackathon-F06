import 'package:flutter/material.dart';

// 家庭共有機能は削除されました
class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭共有'),
      ),
      body: const Center(
        child: Text(
          'この機能は利用できません',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
