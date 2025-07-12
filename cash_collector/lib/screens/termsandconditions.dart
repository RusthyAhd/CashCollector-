import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  final VoidCallback? onAgree;

  const TermsAndConditionsPage({super.key, this.onAgree});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Please read and agree to the following terms before continuing.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _TermItem(
                  number: "1",
                  title:"💰 Incentive Eligibility",
                  en: "If you collect more than Rs.10,000 above the weekly target, you will receive an incentive.",
                  si: "ඔබ සතිපතා ඉලක්කයට වඩා රු.10,000කට වඩා මුදලක් එකතු කළහ ාත්, ඔබට වට්ටමක් ලැහේ.",
                  ta: "நீ ங்கள் வார இலக்கக விட ரூ.10,000 க்கும் மமற்பட்ட த ாகககை வசூலி ் ால், ஊக்க ்த ாகக தபறுவீர்கள்.",
                ),
                _TermItem(
                  number: "2",
                  title: "🏪 Daily Shop Visit Required",
                  en: "You must visit all shops daily. No response from a shop in 2 days will be your responsibility.",
                  si: "ඔබ සෑම දිනයකම සියලු වෙළඳසැල් බැලිය යුතුය. දින 2ක් ඇතුළත පිළිතුරක් නොමැතිවීම ඔබේ වගකීම වේ.",
                  ta: "தினமும் கடைகளுக்கு செல்ல வேண்டும். 2 நாட்களில் பதில் இல்லை என்றால், அது உங்கள் பொறுப்பு.",
                ),
                _TermItem(
                  number: "3",
                  title: "💸 Daily Payment & Receipt Submission",
                  en: "Do not keep money in hand. You must pay daily and send the receipt. Otherwise, it affects your salary.",
                  si: "මුදල් අතින් තබා නොගන්න. ඔබ සෑම දිනකම ගෙවිය යුතු අතර රිසිට්පත යවන්න. නැතහොත් ඔබේ වැටුපට බලපායි.",
                  ta: "பணம் கையில் வைத்திருக்க வேண்டாம். தினமும் செலுத்தி ரசீதை அனுப்ப வேண்டும். இல்லையெனில் சம்பளத்தில் பாதிப்பு ஏற்படும்.",
                ),
                _TermItem(
                  number: "4",
                  title: "⚠️ Responsibility for Lost Money",
                  en: "If the collected money is lost, it is your full responsibility.",
                  si: "එකතු කළ මුදල් අහිමි වුවහොත් එය ඔබේ සම්පූර්ණ වගකීම වේ.",
                  ta: "வசூலித்த பணம் இழந்தால், அது உங்கள் முழு பொறுப்பு.",
                ),
                _TermItem(
                  number: "5",
                  title: "🎯 Weekly Target Performance",
                  en: "Missing weekly target 3 weeks in a row can affect or terminate your position.",
                  si: "සතියේ ඉලක්කය සති 3ක් තිස්සේ නොමැති වීම ඔබේ තනතුරට බලපානු ඇත හෝ එය අවසන් කළ හැකිය.",
                  ta: "மூன்று வாரங்களுக்கு இலக்கு தவறினால், உங்கள் பதவி பாதிக்கப்படலாம் அல்லது நீக்கப்படும்.",
                ),
                _TermItem(
                  number: "6",
                  title: "📧 Support & Contact",                  
                  en: "For any questions, contact: pegasfles2025@gmail.com",
                  si: "ඕනෑම ගැටළුවකට: pegasfles2025@gmail.com අමතන්න.",
                  ta: "எந்த சந்தேகத்திற்கும்: pegasfles2025@gmail.com என தொடர்பு கொள்ளவும்.",
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAgree ?? () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("I Agree"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final String number;
  final String title;
  final String en;
  final String si;
  final String ta;
  
  const _TermItem({
    required this.number,
    required this.title,
    required this.en,
    required this.si,
    required this.ta, 
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text("   $number $title ", 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text("• $en", style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text("   $si", style: const TextStyle(color: Colors.black54)),
          Text("   $ta", style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
