import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class LegalAwarenessScreen extends StatelessWidget {
  const LegalAwarenessScreen({super.key});

  static const List<Map<String, dynamic>> themes = [
    {
      'title': 'Family & Marriage',
      'category': 'Personal Laws',
      'icon': '👨‍👩‍👧‍👦',
      'details': [
        'Minimum Age: Groom must be 21+ and Bride must be 18+ for Hindu marriages.',
        'Child Marriage: Conducting a child marriage can lead to imprisonment of up to 15 days or a fine of ₹1,000.',
        'Registration: Under Section 8 of the Hindu Marriage Act, marriage registration is governed by state rules. Failure to register does not affect validity.',
        'Divorce Grounds: Include cruelty, desertion for 2+ years, adultery, conversion, mental illness, and mutual consent.',
        'Maintenance: Courts can order a spouse to pay monthly maintenance under Section 125 CrPC regardless of religion.',
        'Child Custody: Courts prioritize the "best interests of the child". No parent has automatic superior rights.',
        'Alimony: Permanent alimony can be awarded to either spouse depending on financial circumstances.',
        'Domestic Violence: Under the PWDVA 2005, victims can seek protection orders, residence orders, and monetary relief.',
      ],
      'url': 'https://nyaaya.org/legal-explainers/family-marriage/',
    },
    {
      'title': 'Money & Property',
      'category': 'Finance & Real Estate',
      'icon': '💰',
      'details': [
        'Bank Fraud: Never share OTPs, PINs or passwords — sharing them increases your own liability.',
        'Zero Liability: If unauthorized transaction reported within 3 working days and bank is at fault, you bear zero liability.',
        'Cheque Bounce: A criminal offence under Section 138, NI Act if the cheque was for a debt. Drawer can be imprisoned up to 2 years.',
        'Property Rights: Women have equal rights to ancestral property after the 2005 amendment to the Hindu Succession Act.',
        'Tenant Rights: Landlord cannot evict a tenant without proper legal notice under the Rent Control Act of the state.',
        'Consumer Rights: File a complaint with the Consumer Forum for defective goods/services within 2 years of cause.',
        'EPF: Employees earning up to ₹15,000/month in covered establishments must mandatorily join PF.',
        'Inheritance: In the absence of a will, property is divided by personal law (Hindu, Muslim, Christian, etc.).',
      ],
      'url': 'https://nyaaya.org/legal-explainers/money-property/',
    },
    {
      'title': 'Crimes & Violence',
      'category': 'Criminal Law',
      'icon': '⚖️',
      'details': [
        'Domestic Violence: File a complaint under the PWDVA 2005 at the nearest Magistrate\'s court. You do not need a lawyer.',
        'Sexual Harassment at Work: The POSH Act mandates workplaces with 10+ employees to have an Internal Committee (IC).',
        'Cybercrime: Report online fraud, stalking, and morphing on the Cyber Crime Portal (cybercrime.gov.in).',
        'Acid Attack: Punishable with 10 years to life imprisonment. Victim entitled to free medical treatment from the state.',
        'Child Sexual Abuse: Covered under the POCSO Act. Any person who knows of a child being abused must report it.',
        'Rape: Police cannot refuse to register an FIR by a rape survivor. Investigation must be complete in 2 months.',
        'Rights of Accused: Cannot be arrested without informing family. Must be produced before magistrate within 24 hours.',
        'Bail: You can apply for bail even before appearing in court if you anticipate arrest (Anticipatory Bail under Section 438 CrPC).',
      ],
      'url': 'https://nyaaya.org/legal-explainers/crimes-violence/',
    },
    {
      'title': 'Police & Courts',
      'category': 'Procedural Law',
      'icon': '🚔',
      'details': [
        'FIR: Must be registered for cognizable offenses. Police cannot refuse. Get a free copy of your FIR.',
        'Zero FIR: File at any police station regardless of jurisdiction. It must be transferred to the correct station.',
        'Refusal of FIR: If police refuse, you can write to the Superintendent of Police or file a complaint before a Magistrate.',
        'Bail: Bailable offenses — bail is a right. Non-bailable offenses — bail is at the court\'s discretion.',
        'Right to Lawyer: Every arrested person has the right to be represented by a lawyer of their choice.',
        'Handcuffing Rules: Handcuffing is not automatic; Police must justify it to the court. Must not be done for bailable offenses.',
        'Arrest of Women: A woman cannot be arrested after sunset or before sunrise except in exceptional cases with a female officer.',
        'Witness Rights: Witnesses cannot be detained and must be served summons before being required to appear.',
      ],
      'url': 'https://nyaaya.org/legal-explainers/police-courts/',
    },
    {
      'title': 'Labour & Employment',
      'category': 'Workplace Rights',
      'icon': '🏢',
      'details': [
        'Maternity Benefit: 26 weeks paid leave if worked 80+ days in the preceding 12 months. (Increased from 12 weeks in 2017).',
        'Minimum Wage: Cannot be paid less than the minimum wage set by the Government. Review happens every 5 years.',
        'Workplace Safety: Employers must ensure a safe work environment under the Factories Act or applicable state laws.',
        'Gratuity: Employees with 5+ continuous years of service are eligible for gratuity equal to 15 days salary per year of service.',
        'PF (Provident Fund): Employees earning ≤ ₹15,000/month must contribute 12% of basic salary to EPF.',
        'Wrongful Termination: Retrenchment of workers requires notice, payment of compensation, and government permission for large establishments.',
        'Equal Pay: Equal pay for equal work regardless of gender is a constitutional right.',
        'Contract Labour: Contractors must register and provide statutory benefits including PF, ESI etc. to contract workers.',
      ],
      'url': 'https://nyaaya.org/legal-explainers/labour-employment/',
    },
    {
      'title': 'Health & Environment',
      'category': 'Public Interest',
      'icon': '🌱',
      'details': [
        'Emergency Care: No hospital can deny emergency medical care to any person. This is a constitutionally protected right.',
        'Medical Negligence: Can be filed as a complaint in Consumer Forums for compensation without a criminal proceeding.',
        'Mental Health: Under the Mental Healthcare Act 2017, every person has the right to access mental health care.',
        'Noise Pollution: Permitted daytime noise levels in residential areas are 55 dB. Complaints can be filed with State PCB.',
        'Air Pollution: The Environment Protection Act 1986 prohibits discharge of pollutants beyond prescribed limits.',
        'Smoking: Prohibited in public places like offices, hospitals, restaurants, and public transport under COTPA 2003.',
        'Food Safety: FSSAI regulates food quality. Consumers can file complaints for adulterated or misbranded food products.',
        'Water Rights: Access to clean drinking water is part of the Right to Life under Article 21 of the Constitution.',
      ],
      'url': 'https://nyaaya.org/legal-explainers/health-environment/',
    },
    {
      'title': 'Citizen Rights',
      'category': 'Fundamental Rights',
      'icon': '🤝',
      'details': [
        'RTI: Any citizen can request information from public authorities. Info must be given within 30 days.',
        'RTI BPL: Citizens below the poverty line do not pay any application fee for RTI.',
        'Right to Education: Children aged 6-14 have the right to free and compulsory education (RTE Act).',
        'Right to Privacy: Recognized as a fundamental right by the Supreme Court in the Puttaswamy judgment (2017).',
        'Freedom of Expression: Protected under Art 19(1)(a) but subject to reasonable restrictions (national security, public order, decency).',
        'SC/ST Protection: The SC/ST Prevention of Atrocities Act provides strict punishment for crimes against Dalits and Adivasis.',
        'Consumer Protection: Every consumer has the right to file a complaint for deficient services at the Consumer Disputes Redressal Forum.',
        'Right to Legal Aid: Every accused person who cannot afford legal representation has the right to free legal aid.',
      ],
      'url': 'https://nyaaya.org/legal-explainers/citizen-rights-constitution/',
    },
    {
      'title': 'Government & Elections',
      'category': 'Civic Rights',
      'icon': '🗳️',
      'details': [
        'Right to Vote: Every citizen aged 18+ has the right to vote, unless disqualified for reasons like criminal conviction.',
        'Voter ID: Not the only valid ID for voting — Aadhaar, passport, or driving license can also be used if on the electoral roll.',
        'NOTA: Voters have the right to select "None of the Above" if they are dissatisfied with all candidates.',
        'Electoral Roll: You can register online at voters.eci.gov.in. Deadline is typically 30 days before the election.',
        'Model Code of Conduct: Comes into effect from the date of announcement of elections until results are declared.',
        'Candidate Disclosures: All candidates must disclose criminal records, assets, and liabilities in their affidavit.',
        'Campaign Finance: Political parties and candidates must disclose campaign funding sources above a certain threshold.',
        'Right to Information: Citizens can ask government authorities about public schemes, funds, and plans using RTI.',
      ],
      'url': 'https://nyaaya.org/legal-explainers/government-elections/',
    },
    {
      'title': 'Media & IP',
      'category': 'Information Law',
      'icon': '📱',
      'details': [
        'Defamation (Civil): Filing a civil defamation suit can result in the court awarding monetary damages to the victim.',
        'Defamation (Criminal): Under Sections 499–500 IPC, criminal defamation is punishable with imprisonment up to 2 years.',
        'Copyright: Automatically protects original work from the moment of creation. No registration required.',
        'Copyright Duration: Lasts for the creator\'s lifetime + 60 years after death in most cases.',
        'Plagiarism: While not a crime per se, it can violate copyright law and result in civil suits.',
        'Right to Privacy Online: Any unauthorized use, sharing, or morphing of personal photos is an offense under IT Act 2000.',
        'Fake News: Knowingly spreading false information that causes public alarm or disorder is punishable under Indian law.',
        'Censorship: The government can restrict publication of material that is against national security, decency or public order.',
      ],
      'url': 'https://nyaaya.org/legal-explainers/media-intellectual-property/',
    },
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Legal Awareness'),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroSection(),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                color: AppConstants.accentColor,
              ),
              const SizedBox(width: 12),
              const Text(
                'Key Legal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...themes.map((theme) => _buildThemeCard(context, theme)).toList(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.balance, color: AppConstants.accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Know Your Rights',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Read important legal facts and guidelines sourced from Nyaaya.org to help you understand your rights and responsibilities in India.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, Map<String, dynamic> theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppConstants.primaryColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Text(theme['icon'] ?? '📖', style: const TextStyle(fontSize: 24)),
          title: Text(
            theme['title']!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            theme['category']!,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.accentColor.withOpacity(0.7),
            ),
          ),
          iconColor: AppConstants.accentColor,
          collapsedIconColor: AppConstants.accentColor,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  ...(theme['details'] as List<String>).map((detail) {
                    final colonIndex = detail.indexOf(':');
                    final hasTitle = colonIndex > 0 && colonIndex < 35;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: AppConstants.accentColor, fontSize: 18)),
                          Expanded(
                            child: hasTitle
                                ? RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                        text: detail.substring(0, colonIndex + 1),
                                        style: const TextStyle(
                                          color: AppConstants.accentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                      TextSpan(
                                        text: detail.substring(colonIndex + 1),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ]),
                                  )
                                : Text(
                                    detail,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.4,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _launchUrl(theme['url']!),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Read Full Guide on Nyaaya.org'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppConstants.accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'Information sourced from Nyaaya.org — India\'s Laws Explained.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _launchUrl('https://nyaaya.org'),
            child: const Text(
              'Visit Nyaaya.org for complete legal guides',
              style: TextStyle(color: AppConstants.accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
