import 'package:flutter/material.dart';
import 'steps/goals_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/education_step.dart';
import 'steps/experience_step.dart';
import 'steps/skills_step.dart';
import 'template_screen.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<String> _stepTitles = ['Your Goals', 'Personal Info', 'Education', 'Experience', 'Skills'];

  void _goNext() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TemplateScreen()),
      );
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_stepTitles[_currentStep])),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentStep + 1) / _stepTitles.length),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                GoalsStep(),
                PersonalInfoStep(),
                EducationStep(),
                ExperienceStep(),
                SkillsStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: _goBack, child: const Text('Back')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _goNext,
                    child: Text(_currentStep == _stepTitles.length - 1 ? 'Choose Template' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
