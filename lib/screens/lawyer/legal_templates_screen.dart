import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../utils/constants.dart';
import '../../utils/download_helper.dart' as dh;

class LegalTemplatesScreen extends StatelessWidget {
  const LegalTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Legal Templates'),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.secondaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: AppConstants.accentColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Legal Document Drafts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Ready-to-use formats', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._buildCategories(context),
        ],
      ),
    );
  }

  List<Widget> _buildCategories(BuildContext context) {
    return _templateData.map((category) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: AppConstants.accentColor,
            collapsedIconColor: Colors.white54,
            title: Text(
              category['category'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            leading: Icon(category['icon'] as IconData, color: AppConstants.accentColor),
            children: (category['items'] as List<Map<String, String>>).map((item) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                title: Text(item['title']!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TemplateDetailScreen(
                        title: item['title']!,
                        content: item['content'] ?? 'Document content for ${item['title']} will go here.\n\n[DRAFT TEMPLATE PENDING CONTENT]',
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      );
    }).toList();
  }
}

class TemplateDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const TemplateDetailScreen({super.key, required this.title, required this.content});


  Future<void> _universalDownload({
    required BuildContext context,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    try {
      if (kIsWeb && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Starting Download in Browser...'), backgroundColor: AppConstants.accentColor),
        );
      }

      await dh.downloadFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );

      if (!kIsWeb && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File generated: $fileName'),
            backgroundColor: AppConstants.accentColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download Error: $e'), backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  Future<void> _downloadAsPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                content,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 5),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final sanitizedTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      
      await _universalDownload(
        context: context,
        fileName: '${sanitizedTitle}_Draft_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  Future<void> _downloadAsDoc(BuildContext context) async {
    try {
      final sanitizedTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final docContent = "$title\n\n$content";
      final bytes = utf8.encode(docContent);
      
      await _universalDownload(
        context: context,
        fileName: '${sanitizedTitle}_Draft_${DateTime.now().millisecondsSinceEpoch}.doc',
        bytes: bytes,
        mimeType: 'application/msword',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate DOC: $e'), backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: AppConstants.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy text',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document copied to clipboard')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: () => _downloadAsPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Download DOC',
            onPressed: () => _downloadAsDoc(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.6, fontFamily: 'serif'),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'btn1',
            onPressed: () => _downloadAsDoc(context),
            backgroundColor: AppConstants.secondaryColor,
            icon: const Icon(Icons.description, color: Colors.white),
            label: const Text('Download DOC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'btn2',
            onPressed: () => _downloadAsPdf(context),
            backgroundColor: AppConstants.accentColor,
            icon: const Icon(Icons.picture_as_pdf, color: AppConstants.primaryColor),
            label: const Text('Download PDF', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

final List<Map<String, dynamic>> _templateData = [
  {
    'category': 'Banking & Finance',
    'icon': Icons.account_balance,
    'items': [
      {'title': 'Legal Notice for Recovery of Money', 'content': _recoveryOfMoneyText},
      {'title': 'Cheque Bounce Notice Format', 'content': _chequeBounceText},
      {'title': 'Legal Notice for Insurance Claim', 'content': _insuranceClaimText},
      {'title': 'Loan Agreement with Security', 'content': _securedLoanText},
      {'title': 'Loan Agreement', 'content': _unsecuredLoanText},
      {'title': 'Deed of Hypothecation HP', 'content': _hypothecationText},
    ],
  },
  {
    'category': 'Contracts & Agreements',
    'icon': Icons.handshake,
    'items': [
      {'title': 'Lease Deed / Rent Agreement', 'content': _rentAgreementText},
      {'title': 'Agreement for Sale of a House', 'content': _saleAgreementText},
      {'title': 'Simple Mortgage Deed', 'content': _mortgageDeedText},
      {'title': 'Leave and License Agreement', 'content': _leaveLicenseText},
      {'title': 'Legal Notice for Breach of Trust', 'content': _breachTrustText},
      {'title': 'Legal Notice for Cancellation of Sale Agreement', 'content': _cancelSaleText},
      {'title': 'Legal Notice for Non-performance', 'content': _nonPerformanceText},
    ],
  },
  {
    'category': 'Corporate & Business',
    'icon': Icons.business,
    'items': [
      {'title': 'Partnership Deed', 'content': _partnershipDeedText},
      {'title': 'Non-Disclosure Agreement (NDA)', 'content': _ndaText},
      {'title': 'Shareholders Agreement', 'content': _shareholderText},
      {'title': 'Employee Service Agreement', 'content': _employmentAgreementText},
      {'title': 'Legal Notice for Non-Payment of Invoice', 'content': _unpaidInvoiceText},
      {'title': 'Legal Notice for Wrongful Termination', 'content': _wrongfulTerminationText},
      {'title': 'Franchise Agreement', 'content': _franchiseText},
    ],
  },
  {
    'category': 'Criminal Law',
    'icon': Icons.gavel,
    'items': [
      {'title': 'Anticipatory Bail Petition Format', 'content': _anticipatoryBailText},
      {'title': 'Bail Application Format', 'content': _regularBailText},
      {'title': 'Draft Criminal Complaint for Harassment', 'content': _harassmentComplaintText},
      {'title': 'Legal Notice for Defamation', 'content': _defamationNoticeText},
      {'title': 'Legal Notice for Trespassing', 'content': _trespassNoticeText},
      {'title': 'Complaint Letter to Police for Life Threat', 'content': _policeLetterText},
    ],
  },
  {
    'category': 'Divorce & Family Law',
    'icon': Icons.family_restroom,
    'items': [
      {'title': 'Mutual Divorce Petition', 'content': _mutualDivorceText},
      {'title': 'Notice to Wife for Restitution of Conjugal Rights', 'content': _restitutionNoticeText},
      {'title': 'Legal Notice for Property Partition', 'content': _partitionNoticeText},
      {'title': 'Deed of Gift of Moveable/Immovable Property', 'content': _giftDeedText},
      {'title': 'Partition Deed', 'content': _partitionDeedText},
      {'title': 'Separation Agreement between Husband and Wife', 'content': _separationAgreementText},
      {'title': 'Deed of Adoption', 'content': _adoptionDeedText},
    ],
  },
  {
    'category': 'Property Law',
    'icon': Icons.real_estate_agent,
    'items': [
      {'title': 'Gift Deed for Immovable Property', 'content': _giftDeedText},
      {'title': 'Gift Deed for Gifting Cash', 'content': _giftCashText},
      {'title': 'Letter to Builder for Delay in Possession', 'content': _delayPossessionText},
      {'title': 'Legal Notice for Recovery of Security Deposit', 'content': _securityDepositText},
    ],
  },
];

// --- SAMPLE DOCUMENT CONTENT ---

const String _recoveryOfMoneyText = '''LEGAL NOTICE FOR RECOVERY OF MONEY\n\nTo,\n[Name of Defaulter]\n[Address]\n\nSubject: Legal Notice for Recovery of Money.\n\nSir/Madam,\n\nUnder instruction from and on behalf of my client [Client Name], resident of [Client Address], I serve you with the following notice:\n\n1. That you approached my client on [Date] requesting a friendly loan of Rs. [Amount]/- for your personal needs.\n2. That my client, trusting your word, advanced the said amount via [Mode of Payment] on [Date].\n3. That you promised to repay the said loan amount on or before [Due Date].\n4. That despite repeated requests and demands, you have failed and neglected to repay the amount.\n\nI hereby call upon you to pay the sum of Rs. [Amount]/- along with interest @ [Rate]% p.a. from the date of default till actual realization, within 15 days from the receipt of this notice, failing which my client shall be constrained to initiate civil and criminal proceedings against you.\n\n[Lawyer Name]\nAdvocate''';

const String _chequeBounceText = '''LEGAL NOTICE UNDER SECTION 138 OF NI ACT\n\nTo,\n[Name of Drawer]\n[Address]\n\nSubject: Notice under Section 138 of the Negotiable Instruments Act, 1881.\n\nSir/Madam,\n\nUnder instruction from my client [Client Name], I hereby issue this legal notice as under:\n\n1. That in discharge of your legal liability towards my client, you issued Cheque No. [Cheque Number] dated [Date] drawn on [Bank Name], for an amount of Rs. [Amount]/-.\n2. That my client presented the said cheque through their banker [Client's Bank], but the same was returned unpaid with the memo "Insufficient Funds" on [Bounce Date].\n3. That you have intentionally issued a bad cheque to cheat my client.\n\nYou are hereby requested to make the payment of Rs. [Amount]/- within 15 days from the receipt of this notice, failing which a criminal complaint under Section 138 of the Negotiable Instruments Act will be filed against you.\n\n[Lawyer Name]\nAdvocate''';

const String _rentAgreementText = '''RENT AGREEMENT (LEASE DEED)\n\nThis Rent Agreement is made on this [Day] of [Month], [Year] at [City].\n\nBETWEEN\n[Landlord Name], hereinafter called the "LANDLORD".\nAND\n[Tenant Name], hereinafter called the "TENANT".\n\nNOW THIS AGREEMENT WITNESSETH AS UNDER:\n1. That the monthly rent of the premises is agreed at Rs. [Amount]/-.\n2. That the Tenant has paid a security deposit of Rs. [Deposit Amount]/-.\n3. That this agreement is for a period of 11 months commencing from [Start Date].\n4. That the Tenant shall use the premises only for residential purposes.\n\nIN WITNESS WHEREOF the parties have signed this agreement in the presence of witnesses.\n\nLANDLORD ______________________\nTENANT ______________________''';

const String _ndaText = '''NON-DISCLOSURE AGREEMENT (NDA)\n\nThis Non-Disclosure Agreement is entered into on [Date], by and between:\n[Party A Name], located at [Address] (Disclosing Party)\nand\n[Party B Name], located at [Address] (Receiving Party).\n\n1. Definition of Confidential Information:\nIncludes all information or material that has or could have commercial value in the business in which Disclosing Party is engaged.\n\n2. Obligations of Receiving Party:\nReceiving Party shall hold and maintain the Confidential Information in strictest confidence for the sole and exclusive benefit of the Disclosing Party.\n\n[Party A Signature]\n[Party B Signature]''';

const String _mutualDivorceText = '''PETITION FOR MUTUAL CONSENT DIVORCE\n(Under Section 13B of the Hindu Marriage Act, 1955)\n\nIN THE COURT OF PRINCIPAL JUDGE, FAMILY COURT AT [CITY]\n\nIN THE MATTER OF:\n[Husband Name] ...PETITIONER NO. 1\nAND\n[Wife Name] ...PETITIONER NO. 2\n\nMOST RESPECTFULLY SHOWETH:\n1. That the marriage between the parties was solemnized on [Date of Marriage] according to Hindu rites.\n2. That the parties have been living separately since [Date of Separation] due to temperamental differences.\n3. That all efforts for reconciliation have failed.\n4. That the parties have voluntarily agreed to dissolve their marriage by mutual consent.\n\nPRAYER:\nCourt may be pleased to pass a decree of divorce dissolving the marriage by mutual consent.\n\nPETITIONER 1                 PETITIONER 2''';

const String _insuranceClaimText = '''LEGAL NOTICE FOR INSURANCE CLAIM\n\nTo,\n[Insurance Company Name]\n[Address]\n\nSubject: Legal Notice for settlement of Insurance Claim under Policy No. [Policy Number].\n\nSir/Madam,\n\nUnder instruction from my client [Client Name], I hereby state: \n1. My client holds the aforementioned policy.\n2. A valid claim was raised on [Date of Claim].\n3. The claim has been wrongfully repudiated/delayed.\n\nYou are called upon to clear the claim within 15 days, failing which consumer forum proceedings will be initiated.''';

const String _securedLoanText = '''LOAN AGREEMENT WITH SECURITY\n\nThis Agreement is made on [Date] between [Lender Name] and [Borrower Name].\n\n1. Loan Amount: Rs. [Amount].\n2. Security: The Borrower mortgages/pledges [Description of Security] as collateral for said loan.\n3. Repayment: Due on [Date].\n\n[Lender Signature]   [Borrower Signature]''';

const String _unsecuredLoanText = '''LOAN AGREEMENT\n\nThis Agreement is made on [Date] between [Lender Name] and [Borrower Name].\n\n1. Loan Amount: Rs. [Amount].\n2. Interest Rate: [Rate]% p.a.\n3. Repayment Date: [Date].\n\n[Lender Signature]   [Borrower Signature]''';

const String _hypothecationText = '''DEED OF HYPOTHECATION\n\nThis Deed is made on [Date] between [Borrower Name] and [Bank/Lender Name].\n\n1. The Borrower hypothecates the vehicle/goods [Description] as security for the loan of Rs. [Amount].\n2. The underlying asset remains in possession of Borrower but Lender holds first charge.\n\n[Signatures]''';

const String _saleAgreementText = '''AGREEMENT FOR SALE OF HOUSE\n\nBETWEEN [Seller Name] (Vendor) AND [Buyer Name] (Purchaser).\n\n1. Property Address: [Address]\n2. Consideration: Rs. [Total Amount]\n3. Advance Paid: Rs. [Advance Amount]\n4. Balance to be paid during registration.\n\n[Vendor Signature]   [Purchaser Signature]''';

const String _mortgageDeedText = '''SIMPLE MORTGAGE DEED\n\nThis Deed is made by [Mortgagor Name] in favor of [Mortgagee Name].\n\n1. The Mortgagor borrows Rs. [Amount].\n2. The Mortgagor binds himself to repay with interest.\n3. To secure the repayment, Mortgagor mortgages property at [Address] without delivering possession.\n\n[Mortgagor Signature]''';

const String _leaveLicenseText = '''LEAVE AND LICENSE AGREEMENT\n\nBETWEEN [Licensor Name] AND [Licensee Name].\n\n1. Licensed Premises: [Address].\n2. Fees: Rs. [Amount] per month.\n3. Term: 11 Months.\n4. No tenancy rights are created.\n\n[Licensor Signature]   [Licensee Signature]''';

const String _breachTrustText = '''LEGAL NOTICE FOR BREACH OF TRUST\n\nTo, [Defaulter Name]\n\nMy client entrusted you with [Money/Property description] on [Date]. You have misappropriated the same. Return the property/money within 7 days or criminal action under IPC sections for Criminal Breach of Trust will be initiated.''';

const String _cancelSaleText = '''NOTICE FOR CANCELLATION OF SALE AGREEMENT\n\nTo, [Buyer/Seller Name]\n\nDue to your failure to fulfill the conditions of the Sale Agreement dated [Date], the agreement stands cancelled. The advance amount is hereby forfeit/returned as per contract terms.''';

const String _nonPerformanceText = '''NOTICE FOR NON-PERFORMANCE OF CONTRACT\n\nTo, [Party Name]\n\nYou have failed to execute your obligations under the contract dated [Date]. You are given 7 days to perform or pay damages of Rs. [Amount], failing which suit for specific performance will be filed.''';

const String _partnershipDeedText = '''PARTNERSHIP DEED\n\nMade on [Date] between [Partner 1] and [Partner 2].\n\n1. Name of Firm: [Firm Name]\n2. Business Nature: [Description]\n3. Profit Share Ratio: [Ratio]\n4. Capital Contribution: Partner 1 [Amt], Partner 2 [Amt].\n\n[Signatures]''';

const String _shareholderText = '''SHAREHOLDERS AGREEMENT\n\nBetween the Promoters and Investors of [Company Name].\nOutlines the rights of shareholders, voting majorities, board composition, and exit clauses.\n\n[Signatures]''';

const String _employmentAgreementText = '''EMPLOYMENT AGREEMENT\n\nBetween [Company Name] and [Employee Name].\n\n1. Designation: [Title]\n2. Salary: Rs. [Amount] / annum.\n3. Notice Period: [Months] months.\n\n[Employer]  [Employee]''';

const String _unpaidInvoiceText = '''LEGAL NOTICE FOR NON-PAYMENT OF INVOICE\n\nTo, [Company Name]\n\nRegarding Invoice No. [Number] dated [Date] for Rs. [Amount]. Goods/Services were successfully delivered, but payment is overdue. Pay within 15 days or face legal action under MSME Act / Civil Court.''';

const String _wrongfulTerminationText = '''LEGAL NOTICE FOR WRONGFUL TERMINATION\n\nTo, [Company Name]\n\nYou illegally terminated my client on [Date] without mandatory notice or severance. Pay the dues and compensation within 15 days or industrial dispute will be raised.''';

const String _franchiseText = '''FRANCHISE AGREEMENT\n\nBetween Franchisor and Franchisee.\nOutlines brand usage rights, royalties, territory, and quality control.\n\n[Signatures]''';

const String _anticipatoryBailText = '''PETITION FOR ANTICIPATORY BAIL\n\nUnder Section 438 CrPC.\nApplicant apprehends arrest in FIR No. [Number]. Applicant is innocent and falsely implicated. Ready to join investigation.\n\nPRAYER: Grant anticipatory bail.''';

const String _regularBailText = '''APPLICATION FOR REGULAR BAIL\n\nUnder Section 439 CrPC.\nApplicant is currently in judicial custody for FIR No. [Number]. Investigation is complete. Applicant not a flight risk.\n\nPRAYER: Grant bail unconditionally.''';

const String _harassmentComplaintText = '''CRIMINAL COMPLAINT FOR HARASSMENT\n\nTo, SHO [Police Station]\n\nApplicant is facing constant harassment and stalking from [Accused Name]. Request urgent registration of FIR under relevant IPC/BNS sections.''';

const String _defamationNoticeText = '''LEGAL NOTICE FOR DEFAMATION\n\nTo, [Defaulter]\n\nYou published false and malicious statements against my client on [Date/Platform]. Withdraw the statements, tender an unconditional apology, and pay Rs. [Amount] as damages within 7 days, or civil/criminal suit will follow.''';

const String _trespassNoticeText = '''LEGAL NOTICE FOR TRESPASS\n\nTo, [Defaulter]\n\nYou illegally entered/occupied my client's property at [Address] on [Date]. Vacate immediately or face criminal trespass charges.''';

const String _policeLetterText = '''LETTER TO POLICE FOR LIFE THREAT\n\nTo, SHO [Police Station]\n\nRequesting immediate police protection. I have received credible death threats from [Name/Number] on [Date]. Please register an FIR.''';

const String _restitutionNoticeText = '''LEGAL NOTICE FOR RESTITUTION OF CONJUGAL RIGHTS\n\nTo, [Spouse Name]\n\nYou left the matrimonial home without reasonable cause on [Date]. My client requests you to return and resume conjugal life within 15 days.''';

const String _partitionNoticeText = '''LEGAL NOTICE FOR PROPERTY PARTITION\n\nTo, [Co-owner Name]\n\nMy client is a legal heir to the ancestral property at [Address]. Requesting an amicable partition by metes and bounds within 30 days, failing which an administration suit will be filed.''';

const String _giftDeedText = '''GIFT DEED\n\nI, [Donor Name], out of natural love and affection, do hereby unconditionally gift my property at [Address] / moveables to [Donee Name].\n\n[Donor Signature]   [Donee Signature]''';

const String _partitionDeedText = '''PARTITION DEED\n\nBetween Co-owners. The ancestral property is hereby mutually divided into specific shares marked as Schedule A, B, C.\n\n[Signatures]''';

const String _separationAgreementText = '''SEPARATION AGREEMENT\n\nHusband and Wife mutually agree to live separately. Outlines child custody, visitation rights, and maintenance clauses pending formal divorce.\n\n[Signatures]''';

const String _adoptionDeedText = '''DEED OF ADOPTION\n\n[Adoptive Parents] hereby legally adopt [Child Name] from [Biological Parents / Agency] with all legal rights and duties of natural born parents.\n\n[Signatures]''';

const String _giftCashText = '''GIFT DEED FOR CASH\n\nI, [Donor], out of natural love, gift Rs. [Amount] to [Donee] via Bank Transfer [Ref]. This transfer is absolute and irrevocable.\n\n[Donor]   [Donee]''';

const String _delayPossessionText = '''NOTICE TO BUILDER FOR DELAY\n\nTo, [Builder Name]\n\nPossession of Flat No. [Number] was due on [Date]. Requesting immediate handover or refund with interest as per RERA guidelines.''';

const String _securityDepositText = '''NOTICE FOR REFUND OF SECURITY DEPOSIT\n\nTo, [Landlord Name]\n\nI vacated the premises at [Address] on [Date]. You are illegally holding the security deposit of Rs. [Amount]. Refund within 7 days or legal action will follow.''';

