import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/household_provider.dart';

class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  final _householdNameController = TextEditingController();
  final _joinCodeController = TextEditingController();

  @override
  void dispose() {
    _householdNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    final name = _householdNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('世帯名を入力してください')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final householdId = await ref
          .read(firestoreServiceProvider)
          .createHousehold(name, user.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('世帯を作成しました。コード: $householdId')),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _joinHousehold() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('招待コードを入力してください')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref
          .read(firestoreServiceProvider)
          .joinHousehold(code, user.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('世帯に参加しました')),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(userHouseholdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('世帯管理'),
        backgroundColor: Colors.green,
      ),
      body: householdAsync.when(
        data: (household) {
          if (household == null || !household.exists) {
            return _buildNoHouseholdView();
          }
          return _buildHouseholdView(household.data() as Map<String, dynamic>);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildNoHouseholdView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'まだ世帯に参加していません',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 48),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '新しい世帯を作成',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _householdNameController,
                    decoration: const InputDecoration(
                      labelText: '世帯名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createHousehold,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('世帯を作成'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '既存の世帯に参加',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _joinCodeController,
                    decoration: const InputDecoration(
                      labelText: '招待コード',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _joinHousehold,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('世帯に参加'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdView(Map<String, dynamic> householdData) {
    final members = List<String>.from(householdData['members'] ?? []);
    final settings = householdData['settings'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    householdData['name'] ?? '名前なし',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('世帯ID: ${householdData['householdId']}'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'メンバー: ${members.length}人',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '通知設定',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('通知を有効にする'),
                    value: settings['enableNotifications'] ?? true,
                    onChanged: (value) async {
                      await ref.read(firestoreServiceProvider)
                          .updateNotificationSettings(
                        householdData['householdId'],
                        settings['notificationDays'] ?? 3,
                        value,
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('通知タイミング'),
                    subtitle: Text('賞味期限の${settings['notificationDays'] ?? 3}日前'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Show dialog to change notification days
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '招待',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('以下のコードを共有して家族を招待:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            householdData['householdId'],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            // Copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('コードをコピーしました'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}