import 'package:app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/database_helper.dart';

class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({Key? key}) : super(key: key);

  void _selectCharacter(BuildContext context, String character) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.saveCharacterChoice(character);

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Are you the Panda or the Penguin?',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _selectCharacter(context, 'Panda'),
                    child: _buildCharacterCard(
                      context,
                      'Panda',
                      'assets/images/panda_avatar.png',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectCharacter(context, 'Penguin'),
                    child: _buildCharacterCard(
                      context,
                      'Penguin',
                      'assets/images/penguin_avatar.png',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterCard(
    BuildContext context,
    String name,
    String imagePath,
  ) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: name == "Panda"
                ? const EdgeInsets.all(16.0)
                : const EdgeInsets.all(0),
            child: Image.asset(imagePath),
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
