import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      "colors": [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
      "icon": Icons.electric_meter_rounded,
      "iconColor": AppColors.primary,
      "title": "Votre compteur lit tout seul",
      "desc": "Le module MeterEye se place devant votre compteur CashPower et lit automatiquement votre crédit restant, sans aucune modification de votre installation électrique.",
    },
    {
      "colors": [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
      "icon": Icons.notifications_active_rounded,
      "iconColor": AppColors.secondary,
      "title": "Ne soyez plus jamais pris par surprise",
      "desc": "MeterEye AI analyse votre rythme de consommation et vous prévient avant que votre crédit ne soit épuisé. Fini les coupures imprévues !",
    },
    {
      "colors": [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
      "icon": Icons.insights_rounded,
      "iconColor": const Color(0xFFF59E0B),
      "title": "Comprenez votre consommation",
      "desc": "Graphes clairs, historique détaillé et conseils personnalisés pour maîtriser votre consommation et prolonger votre crédit au maximum.",
    },
  ];

  void _onFinish() {
    Provider.of<AppStateProvider>(context, listen: false).completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _slides.length,
                itemBuilder: (context, idx) {
                  return _buildIllustration(idx);
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildDots(),
                    const SizedBox(height: 32),
                    Text(
                      _slides[_currentPage]['title'],
                      style: AppTextStyles.heading1.copyWith(fontSize: 26),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _slides[_currentPage]['desc'],
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _currentPage < _slides.length - 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _onFinish,
                          child: Text(
                            "Passer",
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text("Suivant →"),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _onFinish,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: const Text("Commencer →"),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(int idx) {
    return Container(
      width: double.infinity,
      color: _slides[idx]['colors'][0],
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _slides[idx]['colors'],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _slides[idx]['icon'],
            size: 110,
            color: _slides[idx]['iconColor'],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? AppColors.primary : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
