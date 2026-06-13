import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/activity_service.dart';
import '../../l10n/app_localizations.dart';
import '../chat/challan_chat_dialog.dart';

class ChallanEditDetailsScreen extends StatefulWidget {
  final String sp462;
  final String challanNo;

  const ChallanEditDetailsScreen({
    super.key,
    required this.sp462,
    required this.challanNo,
  });

  @override
  State<ChallanEditDetailsScreen> createState() =>
      _ChallanEditDetailsScreenState();
}

class _ChallanScreenStateCache {
  final Set<String> expandedSections;
  final Set<String> checkedRejectFields;
  final bool isRadioSelected;
  final String rejectRemark;
  final Set<String> reviewedHighlightedSections;

  const _ChallanScreenStateCache({
    required this.expandedSections,
    required this.checkedRejectFields,
    required this.isRadioSelected,
    required this.rejectRemark,
    required this.reviewedHighlightedSections,
  });
}

class _ChallanEditDetailsScreenState extends State<ChallanEditDetailsScreen> {
  static final Map<String, _ChallanScreenStateCache> _pageStateCache = {};
  static const Map<String, Map<String, String>> _uiText = {
    'en': {
      'customerLabel': 'Customer',
      'exShowroomLabel': 'Ex-Showroom',
      'corporateLabel': 'Corporate',
      'subtotalLabel': 'Subtotal',
      'rtoAmountLabel': 'RTO Amount',
      'insuranceAmtLabel': 'Insurance Amt',
      'netAmountLabel': 'Net Amount',
      'mobileLabel': 'Mobile',
      'challanDetails': 'Challan Details',
      'challanNoLabel': 'Challan No',
      'loadingChallanDetails': 'Loading challan details...',
      'failedToLoadDetails': 'Failed to load details',
      'showSelectionCheckboxes': 'Show Selection Checkboxes',
      'enableCheckboxesHelp':
          'Enable checkboxes to select fields for rejection remarks',
      'rejectRemarkTitle': 'Reject remark',
      'reject': 'Reject',
      'approve': 'Approve',
      'pleaseSelectFieldOrReason':
          'Please check at least one field or enter a rejection reason',
      'basicInformation': 'Basic Information',
      'pricingDetails': 'Pricing Details',
      'discountsAndOffers': 'Discounts & Offers',
      'discountTitle': 'Discount',
      'rtoDetails': 'RTO Details',
      'taxDetails': 'Tax Details',
      'insuranceDetails': 'Insurance Details',
      'financialDetails': 'Financial Details',
      'customerInformation': 'Customer Information',
      'rejectChallan': 'Reject Challan',
      'checkedFieldInfo':
          'Checked fields are added below. You can edit before rejecting:',
      'rejectRemarkHint': 'Reject remark (auto-filled from checked fields)...',
      'allHighlightedMandatory':
          'All highlighted fields are mandatory to check before approval. Please open and review all highlighted sections.',
    },
    'ar': {
      'customerLabel': 'عميل',
      'exShowroomLabel': 'صالة العرض السابقة',
      'corporateLabel': 'شركة كبرى',
      'subtotalLabel': 'المجموع الفرعي',
      'rtoAmountLabel': 'مبلغ RTO',
      'insuranceAmtLabel': 'مبلغ التأمين',
      'netAmountLabel': 'المبلغ الصافي',
      'mobileLabel': 'متحرك',
      'challanDetails': 'تفاصيل تشالان',
      'challanNoLabel': 'رقم تشالان',
      'loadingChallanDetails': 'جارٍ تحميل تفاصيل التحدي...',
      'failedToLoadDetails': 'فشل تحميل التفاصيل',
      'showSelectionCheckboxes': 'إظهار خانات اختيار التحديد',
      'enableCheckboxesHelp':
          'قم بتمكين مربعات الاختيار لتحديد الحقول لملاحظات الرفض',
      'rejectRemarkTitle': 'رفض الملاحظة',
      'reject': 'يرفض',
      'approve': 'يعتمد',
      'pleaseSelectFieldOrReason':
          'يرجى التحقق من حقل واحد على الأقل أو إدخال سبب الرفض',
      'basicInformation': 'المعلومات الأساسية',
      'pricingDetails': 'تفاصيل التسعير',
      'discountsAndOffers': 'الخصومات والعروض',
      'discountTitle': 'تخفيض',
      'rtoDetails': 'تفاصيل RTO',
      'taxDetails': 'التفاصيل الضريبية',
      'insuranceDetails': 'تفاصيل التأمين',
      'financialDetails': 'التفاصيل المالية',
      'customerInformation': 'معلومات العملاء',
      'rejectChallan': 'رفض تشالان',
      'checkedFieldInfo':
          'تتم إضافة الحقول المحددة أدناه. يمكنك التعديل قبل الرفض:',
      'rejectRemarkHint':
          'رفض الملاحظة (يتم ملؤها تلقائيًا من الحقول المحددة)...',
    },
    'as': {
      'customerLabel': 'গ্ৰাহক',
      'exShowroomLabel': 'এক্স-শ্ব’ৰুম',
      'corporateLabel': 'কৰ্পৰেট',
      'subtotalLabel': 'উপমুঠ',
      'rtoAmountLabel': 'আৰ টি অ’ৰ পৰিমাণ',
      'insuranceAmtLabel': 'বীমা Amt',
      'netAmountLabel': 'নিকা ধনৰাশি',
      'mobileLabel': 'ম’বাইল',
      'challanDetails': 'চালানৰ বিৱৰণ',
      'challanNoLabel': 'চালান নং',
      'loadingChallanDetails': 'লোডিং challan বিবরণ...',
      'failedToLoadDetails': 'বিৱৰণ লোড কৰাত ব্যৰ্থ',
      'showSelectionCheckboxes': 'নিৰ্বাচন চেকবাকচসমূহ দেখুৱাওক',
      'enableCheckboxesHelp':
          'প্ৰত্যাখ্যান মন্তব্যসমূহৰ বাবে ক্ষেত্ৰসমূহ নিৰ্ব্বাচন কৰিবলে চেকবাক্সসমূহ সামৰ্থবান কৰক',
      'rejectRemarkTitle': 'মন্তব্য নাকচ কৰক',
      'reject': 'প্ৰত্যাখ্যান',
      'approve': 'অনুমোদন',
      'pleaseSelectFieldOrReason':
          'অনুগ্ৰহ কৰি অন্ততঃ এটা ক্ষেত্ৰ পৰীক্ষা কৰক বা প্ৰত্যাখ্যানৰ কাৰণ দিয়ক',
      'basicInformation': 'মৌলিক তথ্য',
      'pricingDetails': 'মূল্য নিৰ্ধাৰণৰ বিৱৰণ',
      'discountsAndOffers': 'ৰেহাই আৰু অফাৰ',
      'discountTitle': 'ৰেহাই',
      'rtoDetails': 'আৰ টি অ\'ৰ বিৱৰণ',
      'taxDetails': 'কৰ বিৱৰণ',
      'insuranceDetails': 'বীমাৰ বিৱৰণ',
      'financialDetails': 'বিত্তীয় বিৱৰণ',
      'customerInformation': 'গ্ৰাহকৰ তথ্য',
      'rejectChallan': 'চালানক নাকচ কৰক',
      'checkedFieldInfo':
          'পৰীক্ষা কৰা ক্ষেত্ৰসমূহ তলত যোগ কৰা হৈছে। আপুনি নাকচ কৰাৰ আগতে সম্পাদনা কৰিব পাৰে:',
      'rejectRemarkHint':
          'মন্তব্য নাকচ কৰক (নিৰীক্ষণ কৰা ক্ষেত্ৰসমূহৰ পৰা স্বয়ংক্ৰিয়ভাৱে পূৰণ কৰা হৈছে)...',
    },
    'bn': {
      'customerLabel': 'গ্রাহক',
      'exShowroomLabel': 'এক্স-শোরুম',
      'corporateLabel': 'কর্পোরেট',
      'subtotalLabel': 'সাবটোটাল',
      'rtoAmountLabel': 'RTO পরিমাণ',
      'insuranceAmtLabel': 'বীমা Amt',
      'netAmountLabel': 'নেট পরিমাণ',
      'mobileLabel': 'মোবাইল',
      'challanDetails': 'চালানের বিবরণ',
      'challanNoLabel': 'চালান নং',
      'loadingChallanDetails': 'চালানের বিশদ বিবরণ লোড হচ্ছে...',
      'failedToLoadDetails': 'বিশদ লোড করতে ব্যর্থ হয়েছে৷',
      'showSelectionCheckboxes': 'নির্বাচন চেকবক্স দেখান',
      'enableCheckboxesHelp':
          'প্রত্যাখ্যান মন্তব্যের জন্য ক্ষেত্র নির্বাচন করতে চেকবক্স সক্রিয় করুন',
      'rejectRemarkTitle': 'মন্তব্য প্রত্যাখ্যান করুন',
      'reject': 'প্রত্যাখ্যান করুন',
      'approve': 'অনুমোদন করুন',
      'pleaseSelectFieldOrReason':
          'অন্তত একটি ক্ষেত্র চেক করুন বা একটি প্রত্যাখ্যান কারণ লিখুন',
      'basicInformation': 'মৌলিক তথ্য',
      'pricingDetails': 'মূল্য বিবরণ',
      'discountsAndOffers': 'ডিসকাউন্ট এবং অফার',
      'discountTitle': 'ছাড়',
      'rtoDetails': 'RTO বিশদ',
      'taxDetails': 'ট্যাক্সের বিবরণ',
      'insuranceDetails': 'বীমা বিবরণ',
      'financialDetails': 'আর্থিক বিবরণ',
      'customerInformation': 'গ্রাহক তথ্য',
      'rejectChallan': 'চালান প্রত্যাখ্যান করুন',
      'checkedFieldInfo':
          'চেক করা ক্ষেত্র নিচে যোগ করা হয়. আপনি প্রত্যাখ্যান করার আগে সম্পাদনা করতে পারেন:',
      'rejectRemarkHint':
          'মন্তব্য প্রত্যাখ্যান করুন (চেক করা ক্ষেত্র থেকে স্বয়ংক্রিয়ভাবে পূর্ণ)...',
    },
    'de': {
      'customerLabel': 'Kunde',
      'exShowroomLabel': 'Ehemaliger Ausstellungsraum',
      'corporateLabel': 'Unternehmen',
      'subtotalLabel': 'Zwischensumme',
      'rtoAmountLabel': 'RTO-Betrag',
      'insuranceAmtLabel': 'Versicherungsamt',
      'netAmountLabel': 'Nettobetrag',
      'mobileLabel': 'Mobile',
      'challanDetails': 'Challan-Details',
      'challanNoLabel': 'Challan Nr',
      'loadingChallanDetails': 'Challan-Details werden geladen...',
      'failedToLoadDetails': 'Details konnten nicht geladen werden',
      'showSelectionCheckboxes': 'Auswahl-Kontrollkästchen anzeigen',
      'enableCheckboxesHelp':
          'Aktivieren Sie Kontrollkästchen, um Felder für Ablehnungsbemerkungen auszuwählen',
      'rejectRemarkTitle': 'Bemerkung ablehnen',
      'reject': 'Ablehnen',
      'approve': 'Genehmigen',
      'pleaseSelectFieldOrReason':
          'Bitte überprüfen Sie mindestens ein Feld oder geben Sie einen Ablehnungsgrund ein',
      'basicInformation': 'Grundlegende Informationen',
      'pricingDetails': 'Preisdetails',
      'discountsAndOffers': 'Rabatte und Angebote',
      'discountTitle': 'Rabatt',
      'rtoDetails': 'RTO-Details',
      'taxDetails': 'Steuerdetails',
      'insuranceDetails': 'Versicherungsdetails',
      'financialDetails': 'Finanzielle Details',
      'customerInformation': 'Kundeninformationen',
      'rejectChallan': 'Challan ablehnen',
      'checkedFieldInfo':
          'Abgehakte Felder werden unten hinzugefügt. Sie können Folgendes bearbeiten, bevor Sie es ablehnen:',
      'rejectRemarkHint':
          'Bemerkung ablehnen (wird automatisch aus aktivierten Feldern ausgefüllt)...',
    },
    'es': {
      'customerLabel': 'Cliente',
      'exShowroomLabel': 'Ex-sala de exposición',
      'corporateLabel': 'Corporativo',
      'subtotalLabel': 'Total parcial',
      'rtoAmountLabel': 'Cantidad de RTO',
      'insuranceAmtLabel': 'Importe del seguro',
      'netAmountLabel': 'Importe neto',
      'mobileLabel': 'Móvil',
      'challanDetails': 'Detalles de Challan',
      'challanNoLabel': 'Challan No',
      'loadingChallanDetails': 'Cargando detalles de Challan...',
      'failedToLoadDetails': 'No se pudieron cargar los detalles',
      'showSelectionCheckboxes': 'Mostrar casillas de selección',
      'enableCheckboxesHelp':
          'Habilite las casillas de verificación para seleccionar campos para comentarios de rechazo',
      'rejectRemarkTitle': 'Rechazar comentario',
      'reject': 'Rechazar',
      'approve': 'Aprobar',
      'pleaseSelectFieldOrReason':
          'Por favor marque al menos un campo o ingrese un motivo de rechazo',
      'basicInformation': 'Información básica',
      'pricingDetails': 'Detalles de precios',
      'discountsAndOffers': 'Descuentos y ofertas',
      'discountTitle': 'Descuento',
      'rtoDetails': 'Detalles del RTO',
      'taxDetails': 'Detalles de impuestos',
      'insuranceDetails': 'Detalles del seguro',
      'financialDetails': 'Detalles financieros',
      'customerInformation': 'Información del cliente',
      'rejectChallan': 'Rechazar Challan',
      'checkedFieldInfo':
          'Los campos marcados se agregan a continuación. Puedes editar antes de rechazar:',
      'rejectRemarkHint':
          'Rechazar comentario (completado automáticamente a partir de campos marcados)...',
    },
    'fr': {
      'customerLabel': 'Client',
      'exShowroomLabel': 'Ancienne salle d\'exposition',
      'corporateLabel': 'Entreprise',
      'subtotalLabel': 'Total',
      'rtoAmountLabel': 'Montant du RTO',
      'insuranceAmtLabel': 'Montant de l\'assurance',
      'netAmountLabel': 'Montant Net',
      'mobileLabel': 'Mobile',
      'challanDetails': 'Challan Détails',
      'challanNoLabel': 'Challan Non',
      'loadingChallanDetails': 'Chargement des détails de Challan...',
      'failedToLoadDetails': 'Échec du chargement des détails',
      'showSelectionCheckboxes': 'Afficher les cases à cocher de sélection',
      'enableCheckboxesHelp':
          'Activez les cases à cocher pour sélectionner les champs pour les remarques de rejet',
      'rejectRemarkTitle': 'Rejeter la remarque',
      'reject': 'Rejeter',
      'approve': 'Approuver',
      'pleaseSelectFieldOrReason':
          'Veuillez cocher au moins un champ ou saisir un motif de refus',
      'basicInformation': 'Informations de base',
      'pricingDetails': 'Détails des prix',
      'discountsAndOffers': 'Réductions et offres',
      'discountTitle': 'Rabais',
      'rtoDetails': 'Détails du RTO',
      'taxDetails': 'Détails fiscaux',
      'insuranceDetails': 'Détails de l\'assurance',
      'financialDetails': 'Détails financiers',
      'customerInformation': 'Informations client',
      'rejectChallan': 'Rejeter Challan',
      'checkedFieldInfo':
          'Les champs cochés sont ajoutés ci-dessous. Vous pouvez modifier avant de rejeter :',
      'rejectRemarkHint':
          'Rejeter la remarque (remplie automatiquement à partir des champs cochés)...',
    },
    'gu': {
      'customerLabel': 'ગ્રાહક',
      'exShowroomLabel': 'એક્સ-શોરૂમ',
      'corporateLabel': 'કોર્પોરેટ',
      'subtotalLabel': 'પેટાટોટલ',
      'rtoAmountLabel': 'RTO રકમ',
      'insuranceAmtLabel': 'વીમા એએમટી',
      'netAmountLabel': 'ચોખ્ખી રકમ',
      'mobileLabel': 'મોબાઈલ',
      'challanDetails': 'ચલનની વિગતો',
      'challanNoLabel': 'ચલણ નં',
      'loadingChallanDetails': 'ચલનની વિગતો લોડ કરી રહ્યું છે...',
      'failedToLoadDetails': 'વિગતો લોડ કરવામાં નિષ્ફળ',
      'showSelectionCheckboxes': 'પસંદગી ચેકબોક્સ બતાવો',
      'enableCheckboxesHelp':
          'અસ્વીકાર ટિપ્પણી માટે ફીલ્ડ્સ પસંદ કરવા માટે ચેકબોક્સ સક્ષમ કરો',
      'rejectRemarkTitle': 'ટિપ્પણીને નકારી કાઢો',
      'reject': 'અસ્વીકાર કરો',
      'approve': 'મંજૂર',
      'pleaseSelectFieldOrReason':
          'કૃપા કરીને ઓછામાં ઓછું એક ફીલ્ડ તપાસો અથવા અસ્વીકારનું કારણ દાખલ કરો',
      'basicInformation': 'મૂળભૂત માહિતી',
      'pricingDetails': 'કિંમતની વિગતો',
      'discountsAndOffers': 'ડિસ્કાઉન્ટ અને ઑફર્સ',
      'discountTitle': 'ડિસ્કાઉન્ટ',
      'rtoDetails': 'આરટીઓ વિગતો',
      'taxDetails': 'ટેક્સ વિગતો',
      'insuranceDetails': 'વીમા વિગતો',
      'financialDetails': 'નાણાકીય વિગતો',
      'customerInformation': 'ગ્રાહક માહિતી',
      'rejectChallan': 'ચલણ નકારી કાઢો',
      'checkedFieldInfo':
          'ચેક કરેલ ફીલ્ડ્સ નીચે ઉમેરવામાં આવ્યા છે. તમે નકારતા પહેલા સંપાદિત કરી શકો છો:',
      'rejectRemarkHint': 'ટિપ્પણીને નકારો (ચેક કરેલ ફીલ્ડમાંથી સ્વતઃ ભરેલ)...',
    },
    'hi': {
      'customerLabel': 'ग्राहक',
      'exShowroomLabel': 'एक्स-शोरूम',
      'corporateLabel': 'निगमित',
      'subtotalLabel': 'उप-योग',
      'rtoAmountLabel': 'आरटीओ राशि',
      'insuranceAmtLabel': 'बीमा राशि',
      'netAmountLabel': 'शुद्ध राशि',
      'mobileLabel': 'गतिमान',
      'challanDetails': 'चालान विवरण',
      'challanNoLabel': 'चालान नं',
      'loadingChallanDetails': 'चालान विवरण लोड हो रहा है...',
      'failedToLoadDetails': 'विवरण लोड करने में विफल',
      'showSelectionCheckboxes': 'चयन चेकबॉक्स दिखाएँ',
      'enableCheckboxesHelp':
          'अस्वीकृति टिप्पणियों के लिए फ़ील्ड का चयन करने के लिए चेकबॉक्स सक्षम करें',
      'rejectRemarkTitle': 'टिप्पणी अस्वीकार करें',
      'reject': 'अस्वीकार करना',
      'approve': 'मंज़ूरी देना',
      'pleaseSelectFieldOrReason':
          'कृपया कम से कम एक फ़ील्ड जांचें या अस्वीकृति का कारण दर्ज करें',
      'basicInformation': 'मूल जानकारी',
      'pricingDetails': 'मूल्य निर्धारण विवरण',
      'discountsAndOffers': 'छूट और ऑफर',
      'discountTitle': 'छूट',
      'rtoDetails': 'आरटीओ विवरण',
      'taxDetails': 'कर विवरण',
      'insuranceDetails': 'बीमा विवरण',
      'financialDetails': 'वित्तीय विवरण',
      'customerInformation': 'ग्राहक सूचना',
      'rejectChallan': 'चालान अस्वीकार करें',
      'checkedFieldInfo':
          'चेक किए गए फ़ील्ड नीचे जोड़े गए हैं. आप अस्वीकार करने से पहले संपादित कर सकते हैं:',
      'rejectRemarkHint':
          'टिप्पणी अस्वीकार करें (चेक किए गए फ़ील्ड से स्वतः भरा हुआ)...',
    },
    'id': {
      'customerLabel': 'Pelanggan',
      'exShowroomLabel': 'Bekas Showroom',
      'corporateLabel': 'Perusahaan',
      'subtotalLabel': 'Subtotal',
      'rtoAmountLabel': 'Jumlah RTO',
      'insuranceAmtLabel': 'Asuransi Amt',
      'netAmountLabel': 'Jumlah Bersih',
      'mobileLabel': 'Seluler',
      'challanDetails': 'Detail Challan',
      'challanNoLabel': 'Challan No',
      'loadingChallanDetails': 'Memuat detail challan...',
      'failedToLoadDetails': 'Gagal memuat detail',
      'showSelectionCheckboxes': 'Tampilkan Kotak Centang Pilihan',
      'enableCheckboxesHelp':
          'Aktifkan kotak centang untuk memilih bidang komentar penolakan',
      'rejectRemarkTitle': 'Tolak komentar',
      'reject': 'Menolak',
      'approve': 'Menyetujui',
      'pleaseSelectFieldOrReason':
          'Silakan periksa setidaknya satu bidang atau masukkan alasan penolakan',
      'basicInformation': 'Informasi Dasar',
      'pricingDetails': 'Detail Harga',
      'discountsAndOffers': 'Diskon & Penawaran',
      'discountTitle': 'Diskon',
      'rtoDetails': 'Detail RTO',
      'taxDetails': 'Detail Pajak',
      'insuranceDetails': 'Detail Asuransi',
      'financialDetails': 'Detail Keuangan',
      'customerInformation': 'Informasi Pelanggan',
      'rejectChallan': 'Tolak Challan',
      'checkedFieldInfo':
          'Bidang yang dicentang ditambahkan di bawah. Anda dapat mengedit sebelum menolak:',
      'rejectRemarkHint':
          'Tolak komentar (diisi otomatis dari kolom yang dicentang)...',
    },
    'it': {
      'customerLabel': 'Cliente',
      'exShowroomLabel': 'Ex Showroom',
      'corporateLabel': 'Aziendale',
      'subtotalLabel': 'Totale parziale',
      'rtoAmountLabel': 'Importo RTO',
      'insuranceAmtLabel': 'Amt. Assicurazione',
      'netAmountLabel': 'Importo netto',
      'mobileLabel': 'Mobile',
      'challanDetails': 'Dettagli Challan',
      'challanNoLabel': 'Challan no',
      'loadingChallanDetails': 'Caricamento dettagli sfida...',
      'failedToLoadDetails': 'Impossibile caricare i dettagli',
      'showSelectionCheckboxes': 'Mostra caselle di controllo di selezione',
      'enableCheckboxesHelp':
          'Abilita le caselle di controllo per selezionare i campi per i commenti di rifiuto',
      'rejectRemarkTitle': 'Rifiuta l\'osservazione',
      'reject': 'Rifiutare',
      'approve': 'Approvare',
      'pleaseSelectFieldOrReason':
          'Seleziona almeno un campo o inserisci il motivo del rifiuto',
      'basicInformation': 'Informazioni di base',
      'pricingDetails': 'Dettagli sui prezzi',
      'discountsAndOffers': 'Sconti e offerte',
      'discountTitle': 'Sconto',
      'rtoDetails': 'Dettagli RTO',
      'taxDetails': 'Dettagli fiscali',
      'insuranceDetails': 'Dettagli dell\'assicurazione',
      'financialDetails': 'Dettagli finanziari',
      'customerInformation': 'Informazioni sul cliente',
      'rejectChallan': 'Rifiuta Challan',
      'checkedFieldInfo':
          'I campi selezionati vengono aggiunti di seguito. Puoi modificare prima di rifiutare:',
      'rejectRemarkHint':
          'Rifiuta commento (compilato automaticamente dai campi selezionati)...',
    },
    'ja': {
      'customerLabel': 'お客様',
      'exShowroomLabel': '元ショールーム',
      'corporateLabel': '企業向け',
      'subtotalLabel': '小計',
      'rtoAmountLabel': 'RTO金額',
      'insuranceAmtLabel': '保険金額',
      'netAmountLabel': '純額',
      'mobileLabel': '携帯',
      'challanDetails': 'シャランの詳細',
      'challanNoLabel': 'チャラン・ノー',
      'loadingChallanDetails': 'シャランの詳細を読み込み中...',
      'failedToLoadDetails': '詳細のロードに失敗しました',
      'showSelectionCheckboxes': '選択チェックボックスを表示',
      'enableCheckboxesHelp': 'チェックボックスを有効にして拒否のコメントのフィールドを選択します',
      'rejectRemarkTitle': '発言を拒否する',
      'reject': '拒否する',
      'approve': '承認する',
      'pleaseSelectFieldOrReason': '少なくとも 1 つのフィールドをチェックするか、拒否の理由を入力してください',
      'basicInformation': '基本情報',
      'pricingDetails': '価格の詳細',
      'discountsAndOffers': '割引と特典',
      'discountTitle': '割引',
      'rtoDetails': 'RTOの詳細',
      'taxDetails': '税金の詳細',
      'insuranceDetails': '保険の詳細',
      'financialDetails': '財務詳細',
      'customerInformation': '顧客情報',
      'rejectChallan': 'シャランを拒否する',
      'checkedFieldInfo': 'チェックされたフィールドが以下に追加されます。拒否する前に編集できます。',
      'rejectRemarkHint': 'コメントを拒否します (チェックされたフィールドから自動入力されます)...',
    },
    'kn': {
      'customerLabel': 'ಗ್ರಾಹಕ',
      'exShowroomLabel': 'ಎಕ್ಸ್ ಶೋರೂಂ',
      'corporateLabel': 'ಕಾರ್ಪೊರೇಟ್',
      'subtotalLabel': 'ಉಪಮೊತ್ತ',
      'rtoAmountLabel': 'RTO ಮೊತ್ತ',
      'insuranceAmtLabel': 'ವಿಮೆ ಆಮ್ಟ್',
      'netAmountLabel': 'ನಿವ್ವಳ ಮೊತ್ತ',
      'mobileLabel': 'ಮೊಬೈಲ್',
      'challanDetails': 'ಚಲನ್ ವಿವರಗಳು',
      'challanNoLabel': 'ಚಲನ್ ನಂ',
      'loadingChallanDetails': 'ಚಲನ್ ವಿವರಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'failedToLoadDetails': 'ವಿವರಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ',
      'showSelectionCheckboxes': 'ಆಯ್ಕೆ ಚೆಕ್‌ಬಾಕ್ಸ್‌ಗಳನ್ನು ತೋರಿಸಿ',
      'enableCheckboxesHelp':
          'ನಿರಾಕರಣೆ ಟೀಕೆಗಳಿಗಾಗಿ ಕ್ಷೇತ್ರಗಳನ್ನು ಆಯ್ಕೆ ಮಾಡಲು ಚೆಕ್‌ಬಾಕ್ಸ್‌ಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ',
      'rejectRemarkTitle': 'ಟೀಕೆಯನ್ನು ತಿರಸ್ಕರಿಸಿ',
      'reject': 'ತಿರಸ್ಕರಿಸಿ',
      'approve': 'ಅನುಮೋದಿಸಿ',
      'pleaseSelectFieldOrReason':
          'ದಯವಿಟ್ಟು ಕನಿಷ್ಠ ಒಂದು ಕ್ಷೇತ್ರವನ್ನಾದರೂ ಪರಿಶೀಲಿಸಿ ಅಥವಾ ನಿರಾಕರಣೆಯ ಕಾರಣವನ್ನು ನಮೂದಿಸಿ',
      'basicInformation': 'ಮೂಲ ಮಾಹಿತಿ',
      'pricingDetails': 'ಬೆಲೆ ವಿವರಗಳು',
      'discountsAndOffers': 'ರಿಯಾಯಿತಿಗಳು ಮತ್ತು ಕೊಡುಗೆಗಳು',
      'discountTitle': 'ರಿಯಾಯಿತಿ',
      'rtoDetails': 'RTO ವಿವರಗಳು',
      'taxDetails': 'ತೆರಿಗೆ ವಿವರಗಳು',
      'insuranceDetails': 'ವಿಮೆ ವಿವರಗಳು',
      'financialDetails': 'ಹಣಕಾಸಿನ ವಿವರಗಳು',
      'customerInformation': 'ಗ್ರಾಹಕರ ಮಾಹಿತಿ',
      'rejectChallan': 'ಚಲನ್ ಅನ್ನು ತಿರಸ್ಕರಿಸಿ',
      'checkedFieldInfo':
          'ಪರಿಶೀಲಿಸಿದ ಕ್ಷೇತ್ರಗಳನ್ನು ಕೆಳಗೆ ಸೇರಿಸಲಾಗಿದೆ. ತಿರಸ್ಕರಿಸುವ ಮೊದಲು ನೀವು ಸಂಪಾದಿಸಬಹುದು:',
      'rejectRemarkHint':
          'ಟೀಕೆಯನ್ನು ತಿರಸ್ಕರಿಸಿ (ಪರಿಶೀಲಿಸಲಾದ ಕ್ಷೇತ್ರಗಳಿಂದ ಸ್ವಯಂ ತುಂಬಿದೆ)...',
    },
    'ml': {
      'customerLabel': 'ഉപഭോക്താവ്',
      'exShowroomLabel': 'എക്സ്-ഷോറൂം',
      'corporateLabel': 'കോർപ്പറേറ്റ്',
      'subtotalLabel': 'ഉപമൊത്തം',
      'rtoAmountLabel': 'RTO തുക',
      'insuranceAmtLabel': 'ഇൻഷുറൻസ് Amt',
      'netAmountLabel': 'മൊത്തം തുക',
      'mobileLabel': 'മൊബൈൽ',
      'challanDetails': 'ചലാൻ വിശദാംശങ്ങൾ',
      'challanNoLabel': 'ചലാൻ നമ്പർ',
      'loadingChallanDetails': 'ചലാൻ വിശദാംശങ്ങൾ ലോഡുചെയ്യുന്നു...',
      'failedToLoadDetails': 'വിശദാംശങ്ങൾ ലോഡുചെയ്യുന്നതിൽ പരാജയപ്പെട്ടു',
      'showSelectionCheckboxes': 'തിരഞ്ഞെടുക്കൽ ചെക്ക്ബോക്സുകൾ കാണിക്കുക',
      'enableCheckboxesHelp':
          'നിരസിക്കൽ പരാമർശങ്ങൾക്കായി ഫീൽഡുകൾ തിരഞ്ഞെടുക്കുന്നതിന് ചെക്ക്ബോക്സുകൾ പ്രവർത്തനക്ഷമമാക്കുക',
      'rejectRemarkTitle': 'പരാമർശം നിരസിക്കുക',
      'reject': 'നിരസിക്കുക',
      'approve': 'അംഗീകരിക്കുക',
      'pleaseSelectFieldOrReason':
          'ദയവായി ഒരു ഫീൽഡെങ്കിലും പരിശോധിക്കുക അല്ലെങ്കിൽ നിരസിക്കാനുള്ള കാരണം നൽകുക',
      'basicInformation': 'അടിസ്ഥാന വിവരങ്ങൾ',
      'pricingDetails': 'വിലനിർണ്ണയ വിശദാംശങ്ങൾ',
      'discountsAndOffers': 'ഡിസ്കൗണ്ടുകളും ഓഫറുകളും',
      'discountTitle': 'കിഴിവ്',
      'rtoDetails': 'RTO വിശദാംശങ്ങൾ',
      'taxDetails': 'നികുതി വിശദാംശങ്ങൾ',
      'insuranceDetails': 'ഇൻഷുറൻസ് വിശദാംശങ്ങൾ',
      'financialDetails': 'സാമ്പത്തിക വിശദാംശങ്ങൾ',
      'customerInformation': 'ഉപഭോക്തൃ വിവരങ്ങൾ',
      'rejectChallan': 'ചലാൻ നിരസിക്കുക',
      'checkedFieldInfo':
          'പരിശോധിച്ച ഫീൽഡുകൾ ചുവടെ ചേർക്കുന്നു. നിരസിക്കുന്നതിന് മുമ്പ് നിങ്ങൾക്ക് എഡിറ്റ് ചെയ്യാം:',
      'rejectRemarkHint':
          'പരാമർശം നിരസിക്കുക (ചെക്കുചെയ്ത ഫീൽഡുകളിൽ നിന്ന് സ്വയമേവ പൂരിപ്പിച്ചത്)...',
    },
    'mr': {
      'customerLabel': 'ग्राहक',
      'exShowroomLabel': 'एक्स-शोरूम',
      'corporateLabel': 'कॉर्पोरेट',
      'subtotalLabel': 'बेरजे',
      'rtoAmountLabel': 'RTO रक्कम',
      'insuranceAmtLabel': 'विमा Amt',
      'netAmountLabel': 'निव्वळ रक्कम',
      'mobileLabel': 'मोबाईल',
      'challanDetails': 'चलन तपशील',
      'challanNoLabel': 'चलन क्र',
      'loadingChallanDetails': 'चलन तपशील लोड करत आहे...',
      'failedToLoadDetails': 'तपशील लोड करण्यात अयशस्वी',
      'showSelectionCheckboxes': 'निवड चेकबॉक्स दाखवा',
      'enableCheckboxesHelp':
          'नाकारलेल्या टिप्पण्यांसाठी फील्ड निवडण्यासाठी चेकबॉक्सेस सक्षम करा',
      'rejectRemarkTitle': 'टिप्पणी नाकारणे',
      'reject': 'नकार द्या',
      'approve': 'मंजूर करा',
      'pleaseSelectFieldOrReason':
          'कृपया किमान एक फील्ड तपासा किंवा नाकारण्याचे कारण प्रविष्ट करा',
      'basicInformation': 'मूलभूत माहिती',
      'pricingDetails': 'किंमतीचे तपशील',
      'discountsAndOffers': 'सवलती आणि ऑफर',
      'discountTitle': 'सवलत',
      'rtoDetails': 'RTO तपशील',
      'taxDetails': 'कर तपशील',
      'insuranceDetails': 'विमा तपशील',
      'financialDetails': 'आर्थिक तपशील',
      'customerInformation': 'ग्राहक माहिती',
      'rejectChallan': 'चलन नाकारणे',
      'checkedFieldInfo':
          'चेक केलेले फील्ड खाली जोडले आहेत. तुम्ही नाकारण्यापूर्वी संपादित करू शकता:',
      'rejectRemarkHint':
          'टिप्पणी नकार द्या (चेक केलेल्या फील्डमधून स्वयंचलितपणे भरलेले)...',
    },
    'nl': {
      'customerLabel': 'Klant',
      'exShowroomLabel': 'Ex-showroom',
      'corporateLabel': 'Zakelijk',
      'subtotalLabel': 'Subtotaal',
      'rtoAmountLabel': 'RTO-bedrag',
      'insuranceAmtLabel': 'Verzekering Amt',
      'netAmountLabel': 'Netto bedrag',
      'mobileLabel': 'Mobiel',
      'challanDetails': 'Challan-details',
      'challanNoLabel': 'Challan Nee',
      'loadingChallanDetails': 'Challan-details laden...',
      'failedToLoadDetails': 'Kan details niet laden',
      'showSelectionCheckboxes': 'Selectievakjes tonen',
      'enableCheckboxesHelp':
          'Schakel selectievakjes in om velden voor afwijzingsopmerkingen te selecteren',
      'rejectRemarkTitle': 'Opmerking afwijzen',
      'reject': 'Afwijzen',
      'approve': 'Goedkeuren',
      'pleaseSelectFieldOrReason':
          'Vink minimaal één veld aan of voer een afwijzingsreden in',
      'basicInformation': 'Basisinformatie',
      'pricingDetails': 'Prijsdetails',
      'discountsAndOffers': 'Kortingen en aanbiedingen',
      'discountTitle': 'Korting',
      'rtoDetails': 'RTO-details',
      'taxDetails': 'Belastinggegevens',
      'insuranceDetails': 'Verzekeringsgegevens',
      'financialDetails': 'Financiële details',
      'customerInformation': 'Klantinformatie',
      'rejectChallan': 'Challan afwijzen',
      'checkedFieldInfo':
          'Hieronder zijn de aangevinkte velden toegevoegd. U kunt het volgende bewerken voordat u het afwijst:',
      'rejectRemarkHint':
          'Opmerking afwijzen (automatisch ingevuld uit aangevinkte velden)...',
    },
    'or': {
      'customerLabel': 'ଗ୍ରାହକ',
      'exShowroomLabel': 'ପୂର୍ବ ଶୋ’ରୁମ୍ |',
      'corporateLabel': 'କର୍ପୋରେଟ୍ |',
      'subtotalLabel': 'ସବଟୋଟାଲ୍ |',
      'rtoAmountLabel': 'RTO ପରିମାଣ',
      'insuranceAmtLabel': 'ବୀମା Amt',
      'netAmountLabel': 'ନିଟ୍ ପରିମାଣ',
      'mobileLabel': 'ମୋବାଇଲ୍ |',
      'challanDetails': 'ଚ୍ୟାଲେନ୍ ବିବରଣୀଗୁଡିକ |',
      'challanNoLabel': 'ଚ୍ୟାଲେନ୍ ନଂ',
      'loadingChallanDetails': 'ଚ୍ୟାଲେନ୍ ବିବରଣୀ ଲୋଡ୍ କରୁଛି ...',
      'failedToLoadDetails': 'ବିବରଣୀ ଲୋଡ୍ କରିବାରେ ବିଫଳ |',
      'showSelectionCheckboxes': 'ଚୟନ ଚେକ୍ ବକ୍ସଗୁଡିକ ଦେଖାନ୍ତୁ |',
      'enableCheckboxesHelp':
          'ପ୍ରତ୍ୟାଖ୍ୟାନ ଟିପ୍ପଣୀ ପାଇଁ କ୍ଷେତ୍ର ଚୟନ କରିବାକୁ ଚେକ୍ ବକ୍ସଗୁଡିକ ସକ୍ଷମ କରନ୍ତୁ |',
      'rejectRemarkTitle': 'ମନ୍ତବ୍ୟ ପ୍ରତ୍ୟାଖ୍ୟାନ କରନ୍ତୁ |',
      'reject': 'ପ୍ରତ୍ୟାଖ୍ୟାନ କରନ୍ତୁ |',
      'approve': 'ଅନୁମୋଦନ କରନ୍ତୁ |',
      'pleaseSelectFieldOrReason':
          'ଦୟାକରି ଅତିକମରେ ଗୋଟିଏ କ୍ଷେତ୍ର ଯାଞ୍ଚ କରନ୍ତୁ କିମ୍ବା ଏକ ପ୍ରତ୍ୟାଖ୍ୟାନ କାରଣ ପ୍ରବେଶ କରନ୍ତୁ |',
      'basicInformation': 'ମ Basic ଳିକ ସୂଚନା',
      'pricingDetails': 'ମୂଲ୍ୟ ବିବରଣୀ',
      'discountsAndOffers': 'ରିହାତି ଏବଂ ଅଫର୍',
      'discountTitle': 'ରିହାତି',
      'rtoDetails': 'RTO ବିବରଣୀ',
      'taxDetails': 'କର ବିବରଣୀ',
      'insuranceDetails': 'ବୀମା ବିବରଣୀ',
      'financialDetails': 'ଆର୍ଥିକ ବିବରଣୀ',
      'customerInformation': 'ଗ୍ରାହକ ସୂଚନା',
      'rejectChallan': 'ଚ୍ୟାଲେଞ୍ଜକୁ ପ୍ରତ୍ୟାଖ୍ୟାନ କରନ୍ତୁ |',
      'checkedFieldInfo':
          'ଯାଞ୍ଚ ହୋଇଥିବା କ୍ଷେତ୍ରଗୁଡିକ ନିମ୍ନରେ ଯୋଡା ଯାଇଛି | ପ୍ରତ୍ୟାଖ୍ୟାନ କରିବା ପୂର୍ବରୁ ଆପଣ ସଂପାଦନ କରିପାରିବେ:',
      'rejectRemarkHint':
          'ଟିପ୍ପଣୀକୁ ପ୍ରତ୍ୟାଖ୍ୟାନ କରନ୍ତୁ (ଯାଞ୍ଚ ହୋଇଥିବା କ୍ଷେତ୍ରଗୁଡିକରୁ ସ୍ auto ତ - ଭର୍ତି) ...',
    },
    'pa': {
      'customerLabel': 'ਗਾਹਕ',
      'exShowroomLabel': 'ਐਕਸ-ਸ਼ੋਰੂਮ',
      'corporateLabel': 'ਕਾਰਪੋਰੇਟ',
      'subtotalLabel': 'ਉਪ-ਯੋਗ',
      'rtoAmountLabel': 'RTO ਰਕਮ',
      'insuranceAmtLabel': 'ਬੀਮਾ ਐਮ.ਟੀ',
      'netAmountLabel': 'ਕੁੱਲ ਰਕਮ',
      'mobileLabel': 'ਮੋਬਾਈਲ',
      'challanDetails': 'ਚਲਾਨ ਦੇ ਵੇਰਵੇ',
      'challanNoLabel': 'ਚਲਾਨ ਨੰ',
      'loadingChallanDetails': 'ਚਲਾਨ ਦੇ ਵੇਰਵੇ ਲੋਡ ਕੀਤੇ ਜਾ ਰਹੇ ਹਨ...',
      'failedToLoadDetails': 'ਵੇਰਵੇ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਫਲ',
      'showSelectionCheckboxes': 'ਚੋਣ ਚੈੱਕਬਾਕਸ ਦਿਖਾਓ',
      'enableCheckboxesHelp':
          'ਅਸਵੀਕਾਰ ਟਿੱਪਣੀਆਂ ਲਈ ਖੇਤਰ ਚੁਣਨ ਲਈ ਚੈਕਬਾਕਸ ਨੂੰ ਸਮਰੱਥ ਬਣਾਓ',
      'rejectRemarkTitle': 'ਟਿੱਪਣੀ ਨੂੰ ਅਸਵੀਕਾਰ ਕਰੋ',
      'reject': 'ਅਸਵੀਕਾਰ ਕਰੋ',
      'approve': 'ਮਨਜ਼ੂਰ ਕਰੋ',
      'pleaseSelectFieldOrReason':
          'ਕਿਰਪਾ ਕਰਕੇ ਘੱਟੋ-ਘੱਟ ਇੱਕ ਖੇਤਰ ਦੀ ਜਾਂਚ ਕਰੋ ਜਾਂ ਅਸਵੀਕਾਰ ਕਰਨ ਦਾ ਕਾਰਨ ਦਾਖਲ ਕਰੋ',
      'basicInformation': 'ਮੁੱਢਲੀ ਜਾਣਕਾਰੀ',
      'pricingDetails': 'ਕੀਮਤ ਦੇ ਵੇਰਵੇ',
      'discountsAndOffers': 'ਛੋਟਾਂ ਅਤੇ ਪੇਸ਼ਕਸ਼ਾਂ',
      'discountTitle': 'ਛੂਟ',
      'rtoDetails': 'RTO ਵੇਰਵੇ',
      'taxDetails': 'ਟੈਕਸ ਵੇਰਵੇ',
      'insuranceDetails': 'ਬੀਮਾ ਵੇਰਵੇ',
      'financialDetails': 'ਵਿੱਤੀ ਵੇਰਵੇ',
      'customerInformation': 'ਗਾਹਕ ਜਾਣਕਾਰੀ',
      'rejectChallan': 'ਚਲਾਨ ਰੱਦ ਕਰੋ',
      'checkedFieldInfo':
          'ਚੈੱਕ ਕੀਤੇ ਖੇਤਰ ਹੇਠਾਂ ਸ਼ਾਮਲ ਕੀਤੇ ਗਏ ਹਨ। ਤੁਸੀਂ ਅਸਵੀਕਾਰ ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਸੰਪਾਦਿਤ ਕਰ ਸਕਦੇ ਹੋ:',
      'rejectRemarkHint':
          'ਟਿੱਪਣੀ ਨੂੰ ਅਸਵੀਕਾਰ ਕਰੋ (ਚੈੱਕ ਕੀਤੇ ਖੇਤਰਾਂ ਤੋਂ ਸਵੈ-ਭਰਿਆ)...',
    },
    'pl': {
      'customerLabel': 'Klient',
      'exShowroomLabel': 'Były salon',
      'corporateLabel': 'Zbiorowy',
      'subtotalLabel': 'Suma częściowa',
      'rtoAmountLabel': 'Kwota RTO',
      'insuranceAmtLabel': 'Wysokość ubezpieczenia',
      'netAmountLabel': 'Kwota netto',
      'mobileLabel': 'Przenośny',
      'challanDetails': 'Szczegóły Challana',
      'challanNoLabel': 'Chalan nr',
      'loadingChallanDetails': 'Ładowanie szczegółów challanu...',
      'failedToLoadDetails': 'Nie udało się załadować szczegółów',
      'showSelectionCheckboxes': 'Pokaż pola wyboru',
      'enableCheckboxesHelp':
          'Włącz pola wyboru, aby wybrać pola dla uwag o odrzuceniu',
      'rejectRemarkTitle': 'Odrzuć uwagę',
      'reject': 'Odrzucić',
      'approve': 'Zatwierdzić',
      'pleaseSelectFieldOrReason':
          'Proszę zaznaczyć przynajmniej jedno pole lub podać powód odrzucenia',
      'basicInformation': 'Podstawowe informacje',
      'pricingDetails': 'Szczegóły cenowe',
      'discountsAndOffers': 'Rabaty i oferty',
      'discountTitle': 'Rabat',
      'rtoDetails': 'Szczegóły RTO',
      'taxDetails': 'Szczegóły podatku',
      'insuranceDetails': 'Szczegóły ubezpieczenia',
      'financialDetails': 'Szczegóły finansowe',
      'customerInformation': 'Informacje o kliencie',
      'rejectChallan': 'Odrzuć Challana',
      'checkedFieldInfo':
          'Zaznaczone pola zostały dodane poniżej. Możesz edytować przed odrzuceniem:',
      'rejectRemarkHint':
          'Odrzuć uwagę (uzupełniana automatycznie z zaznaczonych pól)...',
    },
    'pt': {
      'customerLabel': 'Cliente',
      'exShowroomLabel': 'Ex-showroom',
      'corporateLabel': 'Corporativo',
      'subtotalLabel': 'Subtotal',
      'rtoAmountLabel': 'Valor do RTO',
      'insuranceAmtLabel': 'Valor do seguro',
      'netAmountLabel': 'Valor líquido',
      'mobileLabel': 'Móvel',
      'challanDetails': 'Detalhes do Challan',
      'challanNoLabel': 'Challan Não',
      'loadingChallanDetails': 'Carregando detalhes do desafio...',
      'failedToLoadDetails': 'Falha ao carregar detalhes',
      'showSelectionCheckboxes': 'Mostrar caixas de seleção de seleção',
      'enableCheckboxesHelp':
          'Ative as caixas de seleção para selecionar campos para comentários de rejeição',
      'rejectRemarkTitle': 'Rejeitar observação',
      'reject': 'Rejeitar',
      'approve': 'Aprovar',
      'pleaseSelectFieldOrReason':
          'Marque pelo menos um campo ou insira um motivo de rejeição',
      'basicInformation': 'Informações Básicas',
      'pricingDetails': 'Detalhes de preços',
      'discountsAndOffers': 'Descontos e ofertas',
      'discountTitle': 'Desconto',
      'rtoDetails': 'Detalhes do RTO',
      'taxDetails': 'Detalhes fiscais',
      'insuranceDetails': 'Detalhes do seguro',
      'financialDetails': 'Detalhes Financeiros',
      'customerInformation': 'Informações do cliente',
      'rejectChallan': 'Rejeitar Challan',
      'checkedFieldInfo':
          'Os campos marcados são adicionados abaixo. Você pode editar antes de rejeitar:',
      'rejectRemarkHint':
          'Rejeitar observação (preenchido automaticamente a partir dos campos marcados)...',
    },
    'ru': {
      'customerLabel': 'Клиент',
      'exShowroomLabel': 'Бывший выставочный зал',
      'corporateLabel': 'Корпоративный',
      'subtotalLabel': 'Итого',
      'rtoAmountLabel': 'Сумма РТО',
      'insuranceAmtLabel': 'Страховая сумма',
      'netAmountLabel': 'Чистая сумма',
      'mobileLabel': 'мобильный',
      'challanDetails': 'Подробности о Чалане',
      'challanNoLabel': 'Чаллан Нет',
      'loadingChallanDetails': 'Загрузка сведений о чалане...',
      'failedToLoadDetails': 'Не удалось загрузить детали',
      'showSelectionCheckboxes': 'Показать флажки выбора',
      'enableCheckboxesHelp':
          'Установите флажки для выбора полей для замечаний об отказе',
      'rejectRemarkTitle': 'Отклонить замечание',
      'reject': 'Отклонять',
      'approve': 'Утвердить',
      'pleaseSelectFieldOrReason':
          'Пожалуйста, проверьте хотя бы одно поле или укажите причину отклонения.',
      'basicInformation': 'Основная информация',
      'pricingDetails': 'Подробности о ценах',
      'discountsAndOffers': 'Скидки и предложения',
      'discountTitle': 'Скидка',
      'rtoDetails': 'Детали РТО',
      'taxDetails': 'Налоговые данные',
      'insuranceDetails': 'Детали страхования',
      'financialDetails': 'Финансовые детали',
      'customerInformation': 'Информация о клиенте',
      'rejectChallan': 'Отклонить Чаллан',
      'checkedFieldInfo':
          'Отмеченные поля добавлены ниже. Прежде чем отклонить, вы можете отредактировать:',
      'rejectRemarkHint':
          'Отклонить замечание (автоматически заполняется из отмеченных полей)...',
    },
    'ta': {
      'customerLabel': 'வாடிக்கையாளர்',
      'exShowroomLabel': 'எக்ஸ்-ஷோரூம்',
      'corporateLabel': 'கார்ப்பரேட்',
      'subtotalLabel': 'துணைத்தொகை',
      'rtoAmountLabel': 'ஆர்டிஓ தொகை',
      'insuranceAmtLabel': 'காப்பீடு ஏஎம்டி',
      'netAmountLabel': 'நிகர தொகை',
      'mobileLabel': 'மொபைல்',
      'challanDetails': 'சலான் விவரங்கள்',
      'challanNoLabel': 'சலான் எண்',
      'loadingChallanDetails': 'சலான் விவரங்களை ஏற்றுகிறது...',
      'failedToLoadDetails': 'விவரங்களை ஏற்றுவதில் தோல்வி',
      'showSelectionCheckboxes': 'தேர்வு பெட்டிகளைக் காட்டு',
      'enableCheckboxesHelp':
          'நிராகரிப்பு கருத்துகளுக்கான புலங்களைத் தேர்ந்தெடுக்க தேர்வுப்பெட்டிகளை இயக்கவும்',
      'rejectRemarkTitle': 'கருத்தை நிராகரிக்கவும்',
      'reject': 'நிராகரிக்கவும்',
      'approve': 'ஒப்புதல்',
      'pleaseSelectFieldOrReason':
          'குறைந்தது ஒரு புலத்தையாவது சரிபார்க்கவும் அல்லது நிராகரிப்பு காரணத்தை உள்ளிடவும்',
      'basicInformation': 'அடிப்படை தகவல்',
      'pricingDetails': 'விலை விவரங்கள்',
      'discountsAndOffers': 'தள்ளுபடிகள் & சலுகைகள்',
      'discountTitle': 'தள்ளுபடி',
      'rtoDetails': 'ஆர்டிஓ விவரங்கள்',
      'taxDetails': 'வரி விவரங்கள்',
      'insuranceDetails': 'காப்பீட்டு விவரங்கள்',
      'financialDetails': 'நிதி விவரங்கள்',
      'customerInformation': 'வாடிக்கையாளர் தகவல்',
      'rejectChallan': 'சலனை நிராகரி',
      'checkedFieldInfo':
          'சரிபார்க்கப்பட்ட புலங்கள் கீழே சேர்க்கப்பட்டுள்ளன. நிராகரிப்பதற்கு முன் நீங்கள் திருத்தலாம்:',
      'rejectRemarkHint':
          'கருத்தை நிராகரி (சரிபார்க்கப்பட்ட புலங்களில் இருந்து தானாக நிரப்பப்பட்டது)...',
    },
    'te': {
      'customerLabel': 'కస్టమర్',
      'exShowroomLabel': 'ఎక్స్-షోరూమ్',
      'corporateLabel': 'కార్పొరేట్',
      'subtotalLabel': 'ఉపమొత్తం',
      'rtoAmountLabel': 'RTO మొత్తం',
      'insuranceAmtLabel': 'భీమా అమ్ట్',
      'netAmountLabel': 'నికర మొత్తం',
      'mobileLabel': 'మొబైల్',
      'challanDetails': 'చలాన్ వివరాలు',
      'challanNoLabel': 'చలాన్ నం',
      'loadingChallanDetails': 'చలాన్ వివరాలను లోడ్ చేస్తోంది...',
      'failedToLoadDetails': 'వివరాలను లోడ్ చేయడంలో విఫలమైంది',
      'showSelectionCheckboxes': 'ఎంపిక చెక్‌బాక్స్‌లను చూపించు',
      'enableCheckboxesHelp':
          'తిరస్కరణ వ్యాఖ్యల కోసం ఫీల్డ్‌లను ఎంచుకోవడానికి చెక్‌బాక్స్‌లను ప్రారంభించండి',
      'rejectRemarkTitle': 'వ్యాఖ్యను తిరస్కరించండి',
      'reject': 'తిరస్కరించు',
      'approve': 'ఆమోదించండి',
      'pleaseSelectFieldOrReason':
          'దయచేసి కనీసం ఒక ఫీల్డ్‌ని తనిఖీ చేయండి లేదా తిరస్కరణ కారణాన్ని నమోదు చేయండి',
      'basicInformation': 'ప్రాథమిక సమాచారం',
      'pricingDetails': 'ధర వివరాలు',
      'discountsAndOffers': 'డిస్కౌంట్లు & ఆఫర్లు',
      'discountTitle': 'తగ్గింపు',
      'rtoDetails': 'RTO వివరాలు',
      'taxDetails': 'పన్ను వివరాలు',
      'insuranceDetails': 'బీమా వివరాలు',
      'financialDetails': 'ఆర్థిక వివరాలు',
      'customerInformation': 'కస్టమర్ సమాచారం',
      'rejectChallan': 'చలాన్‌ని తిరస్కరించండి',
      'checkedFieldInfo':
          'తనిఖీ చేసిన ఫీల్డ్‌లు దిగువన జోడించబడ్డాయి. మీరు తిరస్కరించే ముందు సవరించవచ్చు:',
      'rejectRemarkHint':
          'వ్యాఖ్యను తిరస్కరించండి (చెక్ చేసిన ఫీల్డ్‌ల నుండి స్వయంచాలకంగా పూరించబడింది)...',
    },
    'th': {
      'customerLabel': 'ลูกค้า',
      'exShowroomLabel': 'อดีตโชว์รูม',
      'corporateLabel': 'องค์กร',
      'subtotalLabel': 'ผลรวมย่อย',
      'rtoAmountLabel': 'จำนวนเงิน RTO',
      'insuranceAmtLabel': 'เบี้ยประกันภัย',
      'netAmountLabel': 'จำนวนเงินสุทธิ',
      'mobileLabel': 'มือถือ',
      'challanDetails': 'รายละเอียดชาลัน',
      'challanNoLabel': 'ชาลัน เลขที่',
      'loadingChallanDetails': 'กำลังโหลดรายละเอียด chalan...',
      'failedToLoadDetails': 'โหลดรายละเอียดไม่สำเร็จ',
      'showSelectionCheckboxes': 'แสดงช่องทำเครื่องหมายการเลือก',
      'enableCheckboxesHelp':
          'เปิดใช้งานช่องทำเครื่องหมายเพื่อเลือกช่องสำหรับหมายเหตุการปฏิเสธ',
      'rejectRemarkTitle': 'ปฏิเสธข้อสังเกต',
      'reject': 'ปฏิเสธ',
      'approve': 'อนุมัติ',
      'pleaseSelectFieldOrReason':
          'โปรดตรวจสอบอย่างน้อยหนึ่งช่องหรือป้อนเหตุผลในการปฏิเสธ',
      'basicInformation': 'ข้อมูลพื้นฐาน',
      'pricingDetails': 'รายละเอียดราคา',
      'discountsAndOffers': 'ส่วนลดและข้อเสนอ',
      'discountTitle': 'การลดราคา',
      'rtoDetails': 'รายละเอียด RTO',
      'taxDetails': 'รายละเอียดภาษี',
      'insuranceDetails': 'รายละเอียดการประกันภัย',
      'financialDetails': 'รายละเอียดทางการเงิน',
      'customerInformation': 'ข้อมูลลูกค้า',
      'rejectChallan': 'ปฏิเสธชาลัน',
      'checkedFieldInfo':
          'ช่องที่เลือกจะถูกเพิ่มด้านล่าง คุณสามารถแก้ไขได้ก่อนที่จะปฏิเสธ:',
      'rejectRemarkHint': 'ปฏิเสธหมายเหตุ (กรอกอัตโนมัติจากช่องที่เลือก)...',
    },
    'tr': {
      'customerLabel': 'Müşteri',
      'exShowroomLabel': 'Eski Showroom',
      'corporateLabel': 'Kurumsal',
      'subtotalLabel': 'Ara toplam',
      'rtoAmountLabel': 'RTO Tutarı',
      'insuranceAmtLabel': 'Sigorta Tutarı',
      'netAmountLabel': 'Net Tutar',
      'mobileLabel': 'Mobil',
      'challanDetails': 'Challan Detayları',
      'challanNoLabel': 'Hayır',
      'loadingChallanDetails': 'Challan ayrıntıları yükleniyor...',
      'failedToLoadDetails': 'Ayrıntılar yüklenemedi',
      'showSelectionCheckboxes': 'Seçim Onay Kutularını Göster',
      'enableCheckboxesHelp':
          'Reddetme açıklamalarına ilişkin alanları seçmek için onay kutularını etkinleştirin',
      'rejectRemarkTitle': 'Açıklamayı reddet',
      'reject': 'Reddetmek',
      'approve': 'Onaylamak',
      'pleaseSelectFieldOrReason':
          'Lütfen en az bir alanı işaretleyin veya bir ret nedeni girin',
      'basicInformation': 'Temel Bilgiler',
      'pricingDetails': 'Fiyatlandırma Ayrıntıları',
      'discountsAndOffers': 'İndirimler ve Teklifler',
      'discountTitle': 'İndirim',
      'rtoDetails': 'RTO Ayrıntıları',
      'taxDetails': 'Vergi Ayrıntıları',
      'insuranceDetails': 'Sigorta Detayları',
      'financialDetails': 'Finansal Detaylar',
      'customerInformation': 'Müşteri Bilgileri',
      'rejectChallan': 'Challan\'ı reddet',
      'checkedFieldInfo':
          'İşaretli alanlar aşağıya eklenmiştir. Reddetmeden önce düzenleyebilirsiniz:',
      'rejectRemarkHint':
          'Açıklamayı reddet (işaretli alanlardan otomatik olarak doldurulur)...',
    },
    'ur': {
      'customerLabel': 'گاہک',
      'exShowroomLabel': 'سابق شو روم',
      'corporateLabel': 'کارپوریٹ',
      'subtotalLabel': 'ذیلی کل',
      'rtoAmountLabel': 'آر ٹی او کی رقم',
      'insuranceAmtLabel': 'انشورنس ایم ٹی',
      'netAmountLabel': 'خالص رقم',
      'mobileLabel': 'موبائل',
      'challanDetails': 'چالان کی تفصیلات',
      'challanNoLabel': 'چالان نمبر',
      'loadingChallanDetails': 'چالان کی تفصیلات لوڈ ہو رہی ہیں...',
      'failedToLoadDetails': 'تفصیلات لوڈ کرنے میں ناکام',
      'showSelectionCheckboxes': 'سلیکشن چیک باکسز دکھائیں۔',
      'enableCheckboxesHelp':
          'مسترد ریمارکس کے لیے فیلڈز کو منتخب کرنے کے لیے چیک باکسز کو فعال کریں۔',
      'rejectRemarkTitle': 'ریمارکس کو مسترد کریں۔',
      'reject': 'رد کرنا',
      'approve': 'منظور کرو',
      'pleaseSelectFieldOrReason':
          'براہ کرم کم از کم ایک فیلڈ چیک کریں یا مسترد کرنے کی وجہ درج کریں۔',
      'basicInformation': 'بنیادی معلومات',
      'pricingDetails': 'قیمتوں کی تفصیلات',
      'discountsAndOffers': 'ڈسکاؤنٹس اور آفرز',
      'discountTitle': 'رعایت',
      'rtoDetails': 'آر ٹی او کی تفصیلات',
      'taxDetails': 'ٹیکس کی تفصیلات',
      'insuranceDetails': 'انشورنس کی تفصیلات',
      'financialDetails': 'مالی تفصیلات',
      'customerInformation': 'کسٹمر کی معلومات',
      'rejectChallan': 'چالان مسترد کریں۔',
      'checkedFieldInfo':
          'چیک شدہ فیلڈز نیچے شامل کیے گئے ہیں۔ آپ رد کرنے سے پہلے ترمیم کر سکتے ہیں:',
      'rejectRemarkHint':
          'ریمارکس کو مسترد کریں (چیک شدہ فیلڈ سے خود بخود بھرا ہوا)...',
    },
    'vi': {
      'customerLabel': 'Khách hàng',
      'exShowroomLabel': 'Phòng trưng bày cũ',
      'corporateLabel': 'Công ty',
      'subtotalLabel': 'Tổng phụ',
      'rtoAmountLabel': 'Số tiền RTO',
      'insuranceAmtLabel': 'Số tiền bảo hiểm',
      'netAmountLabel': 'Số tiền ròng',
      'mobileLabel': 'Điện thoại di động',
      'challanDetails': 'Chi tiết Challan',
      'challanNoLabel': 'Challan Không',
      'loadingChallanDetails': 'Đang tải chi tiết challan...',
      'failedToLoadDetails': 'Không thể tải chi tiết',
      'showSelectionCheckboxes': 'Hiển thị hộp kiểm lựa chọn',
      'enableCheckboxesHelp':
          'Bật hộp kiểm để chọn các trường cho nhận xét từ chối',
      'rejectRemarkTitle': 'Từ chối nhận xét',
      'reject': 'Từ chối',
      'approve': 'Chấp thuận',
      'pleaseSelectFieldOrReason':
          'Vui lòng chọn ít nhất một trường hoặc nhập lý do từ chối',
      'basicInformation': 'Thông tin cơ bản',
      'pricingDetails': 'Chi tiết giá cả',
      'discountsAndOffers': 'Giảm giá & Ưu đãi',
      'discountTitle': 'Giảm giá',
      'rtoDetails': 'Chi tiết RTO',
      'taxDetails': 'Chi tiết thuế',
      'insuranceDetails': 'Chi tiết bảo hiểm',
      'financialDetails': 'Chi tiết tài chính',
      'customerInformation': 'Thông tin khách hàng',
      'rejectChallan': 'Từ chối Challan',
      'checkedFieldInfo':
          'Các trường được kiểm tra sẽ được thêm vào bên dưới. Bạn có thể chỉnh sửa trước khi từ chối:',
      'rejectRemarkHint':
          'Từ chối nhận xét (tự động điền từ các trường đã chọn)...',
    },
    'zh': {
      'customerLabel': '顾客',
      'exShowroomLabel': '前陈列室',
      'corporateLabel': '公司的',
      'subtotalLabel': '小计',
      'rtoAmountLabel': '反收购金额',
      'insuranceAmtLabel': '保险金额',
      'netAmountLabel': '净额',
      'mobileLabel': '移动的',
      'challanDetails': '查兰详情',
      'challanNoLabel': '查兰诺',
      'loadingChallanDetails': '正在加载查兰详细信息...',
      'failedToLoadDetails': '无法加载详细信息',
      'showSelectionCheckboxes': '显示选择复选框',
      'enableCheckboxesHelp': '启用复选框以选择拒绝备注字段',
      'rejectRemarkTitle': '拒绝评论',
      'reject': '拒绝',
      'approve': '批准',
      'pleaseSelectFieldOrReason': '请检查至少一个字段或输入拒绝原因',
      'basicInformation': '基本信息',
      'pricingDetails': '定价详情',
      'discountsAndOffers': '折扣和优惠',
      'discountTitle': '折扣',
      'rtoDetails': 'RTO详情',
      'taxDetails': '税务详情',
      'insuranceDetails': '保险详情',
      'financialDetails': '财务详情',
      'customerInformation': '客户信息',
      'rejectChallan': '拒绝查兰',
      'checkedFieldInfo': '下面添加了选中的字段。您可以在拒绝之前进行编辑：',
      'rejectRemarkHint': '拒绝评论（从选中的字段自动填写）...',
    },
  };
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _processing = false;
  String loggedInUserId = '';
  int _unreadChatCount = 0; // unread chat badge
  Set<String> _expandedSections = {'Basic Information'};
  Set<String> _reviewedHighlightedSections = {};
  final Set<String> _checkedRejectFields = {};
  final List<String> _rejectFieldOrder = [];
  final Map<String, String> _fieldKeyToLabel = {};
  final TextEditingController _rejectRemarkController = TextEditingController();
  bool _isRadioSelected = false;
  final GlobalKey _checkboxRowKey = GlobalKey();

  static const Color _primary = Color(0xFF0D3F8A);
  static const Color _secondary = Color(0xFF2C6CE0);
  static const Color _bg = Color(0xFFF4F9FF);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMid = Color(0xFF64748B);
  static const Color _rowBorder = Color(0xFFC7D2FE);

  @override
  void initState() {
    super.initState();
    ActivityService.logActivity(
      activityType: "SCREEN",
      activityName: "ChallanEditDetailsScreen",
      screenName: "ChallanEditDetailsScreen",
    );
    _initializePage();
  }

  @override
  void dispose() {
    _savePageState();
    _rejectRemarkController.dispose();
    super.dispose();
  }

  void _initRejectFieldKeys(List<_SectionDef> sections) {
    _rejectFieldOrder.clear();
    _fieldKeyToLabel.clear();
    for (final section in sections) {
      for (final field in section.fields) {
        _rejectFieldOrder.add(field.fieldKey);
        _fieldKeyToLabel[field.fieldKey] = field.label;
      }
    }
  }

  void _toggleRejectField(String fieldKey, bool? checked) {
    setState(() {
      if (checked == true) {
        _checkedRejectFields.add(fieldKey);
      } else {
        _checkedRejectFields.remove(fieldKey);
      }
      _syncRejectRemark();
      _savePageState();
    });
  }

  void _syncRejectRemark() {
    final labels = <String>[];
    for (final key in _rejectFieldOrder) {
      if (_checkedRejectFields.contains(key)) {
        labels.add(_fieldKeyToLabel[key] ?? key);
      }
    }
    _rejectRemarkController.text = labels.join('\n');
  }

  String _remarkToSave() {
    if (_checkedRejectFields.isNotEmpty) {
      _syncRejectRemark();
    }
    return _rejectRemarkController.text.trim();
  }

  void _restorePageState() {
    final cached = _pageStateCache[widget.sp462];

    if (cached != null) {
      _expandedSections = Set<String>.from(cached.expandedSections);
      _reviewedHighlightedSections = Set<String>.from(cached.reviewedHighlightedSections);
      _checkedRejectFields.addAll(cached.checkedRejectFields);
      _isRadioSelected = cached.isRadioSelected;
      _rejectRemarkController.text = cached.rejectRemark;
    }
  }

  void _savePageState() {
    _pageStateCache[widget.sp462] = _ChallanScreenStateCache(
      expandedSections: Set<String>.from(_expandedSections),
      reviewedHighlightedSections: Set<String>.from(_reviewedHighlightedSections),
      checkedRejectFields: Set<String>.from(_checkedRejectFields),
      isRadioSelected: _isRadioSelected,
      rejectRemark: _rejectRemarkController.text,
    );
  }

  Future<void> _initializePage() async {
    final uid = await ApiService.getUserId();
    loggedInUserId = uid ?? '';
    _restorePageState();
    _loadData();
    _loadUnreadChatCount();
  }

  Future<void> _loadUnreadChatCount() async {
    final count = await ApiService.getUnreadChatCount(widget.sp462);
    if (mounted) {
      setState(() {
        _unreadChatCount = count;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getChallanEditDetails(widget.sp462);
      if (data == null) {
        throw Exception("No data returned for this challan.");
      }
      final l10n = AppLocalizations.of(context)!;
      final sections = _buildSectionsFromData(data, l10n);
      setState(() {
        _data = data;
        _loading = false;

        _initRejectFieldKeys(sections);
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is String && value.isEmpty) return '-';
    return value.toString();
  }

  String? _summary(String template) {
    final text = template.trim();
    if (text.isEmpty || text.endsWith(': -') || text.endsWith(':-')) {
      return null;
    }
    return text;
  }

  List<_SectionDef> _buildSections() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionsFromData(_data!, l10n);
  }

  String _t(String key) {
    final code = Localizations.localeOf(context).languageCode;
    return _uiText[code]?[key] ?? _uiText['en']![key] ?? key;
  }

  List<_SectionDef> _buildSectionsFromData(
    Map<String, dynamic> d,
    AppLocalizations l10n,
  ) {
    const basic = 'Basic Information';
    const pricing = 'Pricing Details';
    const discounts = 'Discounts & Offers';
    const discount = 'Discount';
    const rto = 'RTO Details';
    const tax = 'Tax Details';
    const insurance = 'Insurance Details';
    const financial = 'Financial Details';
    const customer = 'Customer Information';

    return [
      _SectionDef(
        title: basic,
        summary: _summary(
          '${_t('customerLabel')}: ${_formatValue(d['customername'])}',
        ),
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFF3B82F6),
        fields: [
          _FieldData(basic, 'Date', _formatValue(d['cdate'])),
          _FieldData(
            basic,
            'Challan No',
            _formatValue(d['challanno']),
            highlight: true,
          ),
          _FieldData(basic, 'Customer Name', _formatValue(d['customername'])),
          _FieldData(basic, 'Model Name', _formatValue(d['modelname'])),
          _FieldData(basic, 'Variant Name', _formatValue(d['variantname'])),
          _FieldData(basic, 'Color Name', _formatValue(d['colorname'])),
          _FieldData(basic, 'Sales Consultant', _formatValue(d['scname'])),
          _FieldData(basic, 'Team Leader', _formatValue(d['tlname'])),
          _FieldData(basic, 'VIN No', _formatValue(d['vinno'])),
          _FieldData(basic, 'Engine No', _formatValue(d['engineno'])),
        ],
      ),
      _SectionDef(
        title: pricing,
        summary: _summary(
          '${_t('exShowroomLabel')}: ${_formatValue(d['ExshowRoomPrice'])}',
        ),
        icon: Icons.attach_money_rounded,
        iconColor: const Color(0xFF10B981),
        fields: [
          _FieldData(
            pricing,
            'Ex-Showroom Price',
            _formatValue(d['ExshowRoomPrice']),
          ),
          _FieldData(pricing, 'Fasttag', _formatValue(d['fasttag'])),
          _FieldData(
            pricing,
            'Handling Charge',
            _formatValue(d['handlingchrg']),
          ),
          _FieldData(pricing, 'TCS', _formatValue(d['tcs'])),
          _FieldData(pricing, 'TRC', _formatValue(d['trc'])),
          _FieldData(pricing, 'Accessories', _formatValue(d['Accessories'])),
          _FieldData(
            pricing,
            'Additional Warranty',
            _formatValue(d['AdditionalWarranty']),
          ),
          _FieldData(pricing, 'Warranty Year', _formatValue(d['WarrantyYear'])),
          _FieldData(
            pricing,
            'Warranty Amount',
            _formatValue(d['WarrantyAmount']),
          ),
        ],
      ),
      _SectionDef(
        title: discounts,
        summary: _summary(
          '${_t('corporateLabel')}: ${_formatValue(d['Corporateyn'])}',
        ),
        icon: Icons.local_offer_rounded,
        iconColor: const Color(0xFFF59E0B),
        fields: [
          _FieldData(
            discounts,
            'Corporate Y/N',
            _formatValue(d['Corporateyn']),
          ),
          _FieldData(
            discounts,
            'Corporate Amount',
            _formatValue(d['Corporateamount']),
          ),
          _FieldData(
            discounts,
            'Corporate Given',
            _formatValue(d['Corporategiven']),
          ),
          _FieldData(discounts, 'Exchange Y/N', _formatValue(d['Exchangeyn'])),
          _FieldData(
            discounts,
            'Exchange Amount',
            _formatValue(d['Exchangeamount']),
          ),
          _FieldData(
            discounts,
            'Exchange Given',
            _formatValue(d['Exchangegiven']),
          ),
          _FieldData(discounts, 'Loyalty Y/N', _formatValue(d['Loyalityyn'])),
          _FieldData(
            discounts,
            'Loyalty Amount',
            _formatValue(d['Loyalityamount']),
          ),
          _FieldData(
            discounts,
            'Loyalty Given',
            _formatValue(d['Loyalitygiven']),
          ),
          _FieldData(discounts, 'Dealer Y/N', _formatValue(d['dealeryn'])),
          _FieldData(
            discounts,
            'Dealer Amount',
            _formatValue(d['dealeramount']),
          ),
          _FieldData(discounts, 'Dealer Given', _formatValue(d['dealergiven'])),
        ],
      ),
      _SectionDef(
        title: discount,
        summary: _summary(
          '${_t('subtotalLabel')}: ${_formatValue(d['subtotal'])}',
        ),
        icon: Icons.discount_rounded,
        iconColor: const Color(0xFFEC4899),
        fields: [
          _FieldData(
            discount,
            'Ex-Showroom Price',
            _formatValue(d['ExshowRoomPrice']),
          ),
          _FieldData(
            discount,
            'Less of All Encashment Scheme',
            _formatValue(d['lessofallencashmentschemne']),
            critical: true,
          ),
          _FieldData(discount, 'Subtotal', _formatValue(d['subtotal'])),
        ],
      ),
      _SectionDef(
        title: rto,
        summary: _summary(
          '${_t('rtoAmountLabel')}: ${_formatValue(d['RTOAmount'])}',
        ),
        icon: Icons.directions_car_rounded,
        iconColor: const Color(0xFF8B5CF6),
        fields: [
          _FieldData(rto, 'RTO Rate', _formatValue(d['RTORate'])),
          _FieldData(
            rto,
            'RTO Tax Surcharge',
            _formatValue(d['RTOTaxSurcharge']),
          ),
          _FieldData(rto, 'Green Tax', _formatValue(d['GreenTax'])),
          _FieldData(rto, 'Reg Fee', _formatValue(d['RegFee'])),
          _FieldData(rto, 'HPN', _formatValue(d['HPN']), critical: true),
          _FieldData(rto, 'Duplicate', _formatValue(d['Duplicate'])),
          _FieldData(rto, 'Smart Card', _formatValue(d['SmartCard'])),
          _FieldData(rto, 'Other', _formatValue(d['Other'])),
          _FieldData(rto, 'RTO Amount', _formatValue(d['RTOAmount'])),
          _FieldData(rto, 'RTO City', _formatValue(d['rtocity'])),
          _FieldData(rto, 'RTO From', _formatValue(d['rtofrom'])),
          _FieldData(rto, 'RTO Temp', _formatValue(d['RTO TEMP'])),
        ],
      ),
      _SectionDef(
        title: tax,
        summary: _summary(
          '${_t('subtotalLabel')}: ${_formatValue(d['subtotal'])}',
        ),
        icon: Icons.receipt_rounded,
        iconColor: const Color(0xFFEC4899),
        fields: [
          _FieldData(tax, 'GST', _formatValue(d['GST'])),
          _FieldData(tax, 'CESS', _formatValue(d['CESS'])),
          _FieldData(tax, 'SGST', _formatValue(d['sgst'])),
          _FieldData(tax, 'CGST', _formatValue(d['cgst'])),
          _FieldData(tax, 'GST Percentage', _formatValue(d['GSTPercentage'])),
          _FieldData(tax, 'GST Amount', _formatValue(d['GSTAmount'])),
          _FieldData(tax, 'Subtotal', _formatValue(d['subtotal'])),
          _FieldData(tax, 'Amount', _formatValue(d['Amount'])),
        ],
      ),
      _SectionDef(
        title: insurance,
        summary: _summary(
          '${_t('insuranceAmtLabel')}: ${_formatValue(d['insamt'])}',
        ),
        icon: Icons.security_rounded,
        iconColor: const Color(0xFF06B6D4),
        fields: [
          _FieldData(insurance, 'IDV', _formatValue(d['Idv'])),
          _FieldData(insurance, 'IDV Amount', _formatValue(d['IdvAmount'])),
          _FieldData(
            insurance,
            'Insurance Percentage',
            _formatValue(d['InsurancePercentage']),
          ),
          _FieldData(
            insurance,
            'Insurance Per Amount',
            _formatValue(d['InsperAmount']),
          ),
          _FieldData(
            insurance,
            'Discount Percentage',
            _formatValue(d['DiscountPrecentage']),
          ),
          _FieldData(
            insurance,
            'Discount Amount',
            _formatValue(d['DiscountAmount']),
            critical: true,
          ),
          _FieldData(insurance, 'Third Party', _formatValue(d['ThirdParty'])),
          _FieldData(insurance, 'PA Cover', _formatValue(d['PACover'])),
          _FieldData(insurance, 'ZD', _formatValue(d['ZD'])),
          _FieldData(insurance, 'PB', _formatValue(d['PB'])),
          _FieldData(insurance, 'KP', _formatValue(d['KP'])),
          _FieldData(insurance, 'Paid Driver', _formatValue(d['PaidDriver'])),
          _FieldData(
            insurance,
            'Insurance Amount',
            _formatValue(d['InsuranceAmount']),
          ),
          _FieldData(
            insurance,
            'Insurance Company',
            _formatValue(d['inscmpy']),
          ),
          _FieldData(insurance, 'Policy', _formatValue(d['policy'])),
          _FieldData(
            insurance,
            'Insurance Issue Date',
            _formatValue(d['insissuedate']),
          ),
          _FieldData(insurance, 'Insurance Amt', _formatValue(d['insamt'])),
          _FieldData(insurance, 'Insurance Type', _formatValue(d['instype'])),
          _FieldData(
            insurance,
            'Insurance Showroom',
            _formatValue(d['insshowroom']),
          ),
          _FieldData(
            insurance,
            'Previous Insurance Amt',
            _formatValue(d['preinsamt']),
          ),
          _FieldData(insurance, 'NCB', _formatValue(d['NCB'])),
        ],
      ),
      _SectionDef(
        title: financial,
        summary: _summary(
          '${_t('netAmountLabel')}: ${_formatValue(d['netamount'])}',
        ),
        icon: Icons.account_balance_rounded,
        iconColor: const Color(0xFFEF4444),
        fields: [
          _FieldData(
            financial,
            'Net Amount',
            _formatValue(d['netamount']),
            critical: true,
          ),
          _FieldData(
            financial,
            'Less of All Encashment Scheme',
            _formatValue(d['lessofallencashmentschemne']),
            critical: true,
          ),
          _FieldData(
            financial,
            'Hypothecation',
            _formatValue(d['hypothecationname']),
          ),
          _FieldData(financial, 'Bank Name', _formatValue(d['bankname'])),
          _FieldData(
            financial,
            'Bank Amount',
            _formatValue(d['bankamt']),
            critical: true,
          ),
          _FieldData(
            financial,
            'Finance Amount',
            _formatValue(d['financeamt']),
            critical: true,
          ),
          _FieldData(financial, 'Finance Type', _formatValue(d['financetype'])),
          _FieldData(financial, 'Bank Due', _formatValue(d['bankdue'])),
          _FieldData(financial, 'Customer Due', _formatValue(d['custdue'])),
          _FieldData(financial, 'Customer Receive', _formatValue(d['crecive'])),
          _FieldData(financial, 'Finance Receive', _formatValue(d['freceive'])),
          _FieldData(financial, 'RC Amount', _formatValue(d['rcamt'])),
          _FieldData(financial, 'Balance', _formatValue(d['bal'])),
        ],
      ),
      _SectionDef(
        title: customer,
        summary: _summary(
          '${_t('mobileLabel')}: ${_formatValue(d['mobileno'])}',
        ),
        icon: Icons.person_rounded,
        iconColor: const Color(0xFF6366F1),
        fields: [
          _FieldData(customer, 'Address', _formatValue(d['address'])),
          _FieldData(customer, 'Father Name', _formatValue(d['fathername'])),
          _FieldData(customer, 'Mobile No', _formatValue(d['mobileno'])),
          _FieldData(customer, 'Aadhar Card', _formatValue(d['aadharcard'])),
          _FieldData(customer, 'PAN No', _formatValue(d['panno'])),
          _FieldData(customer, 'Nominee Name', _formatValue(d['nomineename'])),
          _FieldData(customer, 'Age', _formatValue(d['age'])),
          _FieldData(customer, 'Relation', _formatValue(d['relation'])),
          _FieldData(customer, 'GSTIN', _formatValue(d['gstin'])),
          _FieldData(customer, 'Title', _formatValue(d['title'])),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(l10n),
          Expanded(
            child: _loading
                ? _buildLoader(l10n)
                : _error != null
                ? _buildError(l10n)
                : _buildContent(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D3F8A), _primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x332C6CE0),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 18),
          child: Row(
            children: [
              _headerIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('challanDetails'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '${_t('challanNoLabel')}: ${widget.challanNo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              _headerIconButton(icon: Icons.refresh_rounded, onTap: _loadData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildLoader(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(strokeWidth: 3.5, color: _primary),
          ),
          SizedBox(height: 18),
          Text(
            _t('loadingChallanDetails'),
            style: TextStyle(
              fontSize: 14,
              color: _textMid,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _t('failedToLoadDetails'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _textMid),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard(AppLocalizations l10n) {
    return Container(
      key: _checkboxRowKey,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rowBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _isRadioSelected = !_isRadioSelected;
            if (!_isRadioSelected) {
              _checkedRejectFields.clear();
              _rejectRemarkController.clear();
            }
            _savePageState();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRadioSelected
                        ? _primary
                        : _textMid.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _isRadioSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('showSelectionCheckboxes'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      _t('enableCheckboxesHelp'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_data == null) return const SizedBox.shrink();

    final sections = _buildSections();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _rowBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < sections.length; i++)
                        _buildSection(
                          section: sections[i],
                          showDivider: i < sections.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Controls card moved below the scroll area so it appears above action buttons
        const SizedBox(height: 14),
        _buildControlsCard(l10n),
        const SizedBox(height: 8),
        if (_checkedRejectFields.isNotEmpty) _buildRejectRemarkPreview(l10n),
        _buildActionButtons(l10n),
      ],
    );
  }

  Widget _buildRejectRemarkPreview(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 6),
              Text(
                '${_t('rejectRemarkTitle')} (${_checkedRejectFields.length} field${_checkedRejectFields.length == 1 ? '' : 's'})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _rejectRemarkController.text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required _SectionDef section,
    required bool showDivider,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = _expandedSections.contains(section.title);

    final hasCriticalField = section.fields.any((f) => f.critical);
    final isReviewed = hasCriticalField && _reviewedHighlightedSections.contains(section.title);
    final summaryMaxWidth = MediaQuery.of(context).size.width < 700
        ? 130.0
        : 460.0;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: hasCriticalField
                ? isReviewed
                    ? const Color(0xFFECFDF5) // Light green background when reviewed
                    : const Color(0xFFFFEBEE) // Light red background when not yet reviewed
                : Colors.transparent,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Material(
              color: Colors.transparent,
              child: ExpansionTile(
                key: ValueKey('${section.title}-$isExpanded'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: EdgeInsets.zero,
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasCriticalField
                            ? isReviewed
                                ? const Color(0xFFD1FAE5) // Light green icon bg
                                : const Color(0xFFFFE5E5) // Light red icon bg
                            : section.iconColor.withValues(alpha: 0.1),

                        borderRadius: BorderRadius.circular(8),

                        border: hasCriticalField
                            ? Border.all(
                                color: isReviewed
                                    ? const Color(0xFF10B981) // Green border when reviewed
                                    : const Color(0xFFFF6B6B), // Red border when not reviewed
                                width: 1.2,
                              )
                            : null,
                      ),

                      child: Icon(
                        section.icon,
                        color: hasCriticalField
                            ? isReviewed
                                ? const Color(0xFF059669) // Green icon when reviewed
                                : const Color(0xFFDC2626) // Red icon when not reviewed
                            : section.iconColor,
                        size: 20,
                      ),
                    ),

                    if (hasCriticalField)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isReviewed
                                ? const Color(0xFF059669) // Green badge when reviewed
                                : const Color(0xFFDC2626), // Red badge when not reviewed
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),

                          child: Icon(
                            isReviewed ? Icons.check : Icons.priority_high,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  _localizedSectionTitle(l10n, section.title),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,

                    color: hasCriticalField
                        ? isReviewed
                            ? const Color(0xFF065F46) // Dark green text when reviewed
                            : const Color(0xFFB91C1C) // Dark red text when not reviewed
                        : _textDark,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (section.summary != null)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: summaryMaxWidth),
                        child: Text(
                          section.summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                      ),
                    if (section.summary != null) const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    if (expanded) {
                      _expandedSections.add(section.title);
                      // Mark critical section as reviewed when user opens it
                      if (hasCriticalField) {
                        _reviewedHighlightedSections.add(section.title);
                      }
                    } else {
                      _expandedSections.remove(section.title);
                    }

                    _savePageState();
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _rowBorder, width: 1.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < section.fields.length; i++)
                            _SectionFieldRow(
                              field: section.fields[i],
                              isEven: i % 2 == 0,
                              isLast: i == section.fields.length - 1,
                              isChecked: _checkedRejectFields.contains(
                                section.fields[i].fieldKey,
                              ),
                              onCheckChanged: (v) => _toggleRejectField(
                                section.fields[i].fieldKey,
                                v,
                              ),
                              showCheckbox: _isRadioSelected,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: _rowBorder),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _processing ? null : _onReject,
                icon: const Icon(Icons.close_rounded, size: 20),
                label: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_t('reject')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _processing ? null : _onApprove,
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_t('approve')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onApprove() async {
    if (_data == null) return;

    // Validate: all highlighted (critical) sections must be expanded before approval
    final sections = _buildSections();
    final highlightedSections = sections
        .where((s) => s.fields.any((f) => f.critical))
        .toList();
    // Allow approve if all highlighted sections have been reviewed (turned green)
    // i.e. the user has opened each one at least once
    final unreviewed = highlightedSections
        .where((s) => !_reviewedHighlightedSections.contains(s.title))
        .toList();

    if (unreviewed.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t('allHighlightedMandatory'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final approvalData = _prepareDataForSubmission(_data!);
      approvalData['loginUserId'] = loggedInUserId;
      approvalData['sp_583'] = loggedInUserId;
      approvalData['sp_584'] = await ApiService.getClientIp();

      final result = await ApiService.approveChallan(approvalData);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          content: Text(result['message'] ?? 'Challan approved successfully'),
        ),
      );
      await ActivityService.logActivity(
        activityType: "APPROVE_CHALLAN",
        activityName: widget.challanNo,
        screenName: "ChallanEditDetailsScreen",
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _onReject() async {
    if (_data == null) return;
    final l10n = AppLocalizations.of(context)!;

    // If checkboxes are not yet enabled, turn them on and scroll to them so
    // the user can select the rejection fields before proceeding.
    if (!_isRadioSelected) {
      setState(() {
        _isRadioSelected = true;
        _savePageState();
      });
      // Scroll the checkbox row into view
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _checkboxRowKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: 0.8, // show near the bottom so sections above are visible
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0D3F8A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Checkboxes enabled — please select the fields you want to flag, then tap Reject again.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Checkboxes are enabled but nothing selected yet
    if (_checkedRejectFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'To reject this challan, please select at least one issue from the highlighted fields.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    _syncRejectRemark();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _RejectDialog(
        remarkController: _rejectRemarkController,
        onSyncFromChecks: _syncRejectRemark,
        hasCheckedFields: _checkedRejectFields.isNotEmpty,
        rejectChallanText: _t('rejectChallan'),
        checkedFieldInfoText: _t('checkedFieldInfo'),
        rejectRemarkHintText: _t('rejectRemarkHint'),
        rejectText: _t('reject'),
        pleaseSelectFieldOrReasonText: _t('pleaseSelectFieldOrReason'),
        cancelText: l10n.cancel,
      ),
    );

    if (confirmed != true) return;

    final remark = _remarkToSave();

    if (remark.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('pleaseSelectFieldOrReason')),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final rejectionData = _prepareDataForSubmission(_data!);
      rejectionData['loginUserId'] = loggedInUserId;
      rejectionData['sp_587'] = loggedInUserId;
      rejectionData['sp_588'] = await ApiService.getClientIp();
      rejectionData['sp_581'] = remark;

      final result = await ApiService.rejectChallan(rejectionData, remark);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(result['message'] ?? 'Challan rejected successfully'),
        ),
      );
      await ActivityService.logActivity(
        activityType: "REJECT_CHALLAN",
        activityName: widget.challanNo,
        screenName: "ChallanEditDetailsScreen",
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Map<String, dynamic> _prepareDataForSubmission(Map<String, dynamic> data) {
    final prepared = Map<String, dynamic>.from(data);
    if (prepared['sp_462'] == null && prepared['unq'] != null) {
      prepared['sp_462'] = prepared['unq'];
    }
    return prepared;
  }

  String _localizedSectionTitle(AppLocalizations l10n, String titleKey) {
    switch (titleKey) {
      case 'Basic Information':
        return _t('basicInformation');
      case 'Pricing Details':
        return _t('pricingDetails');
      case 'Discounts & Offers':
        return _t('discountsAndOffers');
      case 'Discount':
        return _t('discountTitle');
      case 'RTO Details':
        return _t('rtoDetails');
      case 'Tax Details':
        return _t('taxDetails');
      case 'Insurance Details':
        return _t('insuranceDetails');
      case 'Financial Details':
        return _t('financialDetails');
      case 'Customer Information':
        return _t('customerInformation');
      default:
        return titleKey;
    }
  }
}

class _SectionDef {
  final String title;
  final String? summary;
  final IconData icon;
  final Color iconColor;
  final List<_FieldData> fields;

  const _SectionDef({
    required this.title,
    this.summary,
    required this.icon,
    required this.iconColor,
    required this.fields,
  });
}

class _FieldData {
  final String sectionTitle;
  final String label;
  final String value;
  final bool highlight;
  final bool critical;

  String get fieldKey => '$sectionTitle::$label';

  const _FieldData(
    this.sectionTitle,
    this.label,
    this.value, {
    this.highlight = false,
    this.critical = false,
  });
}

class _SectionFieldRow extends StatelessWidget {
  static const Color _borderColor = Color(0xFFC7D2FE);
  static const Color _evenRowColor = Colors.white;
  static const Color _oddRowColor = Color(0xFFEAF1FF);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMid = Color(0xFF64748B);
  static const Color _primary = Color(0xFF1A56DB);

  final _FieldData field;
  final bool isEven;
  final bool isLast;
  final bool isChecked;
  final ValueChanged<bool?> onCheckChanged;
  final bool showCheckbox;

  const _SectionFieldRow({
    required this.field,
    required this.isEven,
    required this.isLast,
    required this.isChecked,
    required this.onCheckChanged,
    required this.showCheckbox,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? _evenRowColor : _oddRowColor,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showCheckbox)
            SizedBox(
              width: 44,
              child: Checkbox(
                value: isChecked,
                onChanged: onCheckChanged,
                activeColor: _primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: _borderColor, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Text(
                field.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textMid,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: field.highlight
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          field.value,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : field.critical
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFE5E5), Color(0xFFFFF3E0)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFFFF6B6B),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),

                            const SizedBox(width: 4),

                            Text(
                              field.value,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Text(
                      field.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  final TextEditingController remarkController;
  final VoidCallback onSyncFromChecks;
  final bool hasCheckedFields;
  final String rejectChallanText;
  final String checkedFieldInfoText;
  final String rejectRemarkHintText;
  final String rejectText;
  final String pleaseSelectFieldOrReasonText;
  final String cancelText;

  const _RejectDialog({
    required this.remarkController,
    required this.onSyncFromChecks,
    required this.hasCheckedFields,
    required this.rejectChallanText,
    required this.checkedFieldInfoText,
    required this.rejectRemarkHintText,
    required this.rejectText,
    required this.pleaseSelectFieldOrReasonText,
    required this.cancelText,
  });

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  @override
  void initState() {
    super.initState();
    ActivityService.logActivity(
      activityType: "SCREEN",
      activityName: "ChallanEditDetailsScreen",
      screenName: "ChallanEditDetailsScreen",
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.hasCheckedFields) {
        widget.onSyncFromChecks();
      }
      setState(() {});
    });
  }

  void _submit() {
    if (widget.hasCheckedFields) {
      widget.onSyncFromChecks();
    }

    final remark = widget.remarkController.text.trim();
    if (remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.pleaseSelectFieldOrReasonText),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Text(
            widget.rejectChallanText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 420, minHeight: 240),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.checkedFieldInfoText,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: widget.remarkController,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.rejectRemarkHintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.rejectText),
        ),
      ],
    );
  }
}
