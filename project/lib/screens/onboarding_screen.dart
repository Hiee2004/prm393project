import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<_OnboardingItem> pages = const [
    _OnboardingItem(
      icon: Icons.checklist_rounded,
      title: 'Plan Your Focus Tasks',
      description:
          'Choose the most important tasks at the beginning of the day and focus on them one by one.',
    ),
    _OnboardingItem(
      icon: Icons.timer_outlined,
      title: 'Stay Focused',
      description:
          'Start a focus session, avoid distractions and track your real working time.',
    ),
    _OnboardingItem(
      icon: Icons.insights_rounded,
      title: 'Review Your Day',
      description:
          'Check completed tasks, focus time, distractions and your daily progress.',
    ),
  ];
  void _goNext() {
    if (currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(microseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = currentPage == pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF43D982),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = pages[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(42),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF43D982,
                                ).withValues(alpha: 0.15),
                                blurRadius: 35,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: 76,
                            color: const Color(0xFF43D982),
                          ),
                        ),

                        const SizedBox(height: 48),

                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF07112D),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color(0xFF65708A),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? const Color(0xFF43D982)
                          : const Color(0xFFD5DCE8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43D982),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    isLastPage ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
