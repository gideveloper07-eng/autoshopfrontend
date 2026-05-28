// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Se connecter';

  @override
  String get companyCode => 'Code des sociétés';

  @override
  String get userId => 'ID de l\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get invalidCompanyCode => 'Code d\'entreprise invalide';

  @override
  String get pleaseEnterCompanyCode => 'Veuillez saisir le code de l\'entreprise';

  @override
  String get pleaseEnterUserId => 'Veuillez saisir votre identifiant utilisateur';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer le mot de passe';

  @override
  String get loginFailed => 'La connexion a échoué';

  @override
  String get loginSuccess => 'Connexion réussie';

  @override
  String get challan => 'Challan';

  @override
  String get pendingChallan => 'En attendant Challan';

  @override
  String get retailIncentive => 'Incitatif au commerce de détail';

  @override
  String get loadingChallans => 'Chargement des défis...';

  @override
  String get failedToLoadChallans => 'Échec du chargement des challans';

  @override
  String get noChallansFound => 'Aucun challan trouvé';

  @override
  String get pullToRefresh => 'Tirez pour actualiser ou revenir plus tard';

  @override
  String get date => 'Date';

  @override
  String get challanDate => 'Date de Challan';

  @override
  String get expectedDeliveryDate => 'Date de livraison prévue';

  @override
  String get challanNo => 'Challan Non';

  @override
  String get customerName => 'Nom du client';

  @override
  String get action => 'Action';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Sauvegarder';

  @override
  String get cancel => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get refresh => 'Rafraîchir';

  @override
  String get showDate => 'Date du spectacle :';

  @override
  String get expectedDelivery => 'Livraison prévue';

  @override
  String records(int count, String plural) {
    return '$count Enregistrer$plural';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionnez la langue';

  @override
  String get languageChanged => 'La langue a changé avec succès';

  @override
  String get home => 'Maison';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Déconnexion';

  @override
  String get confirmLogout => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get loading => 'Chargement...';

  @override
  String get serverError => 'Erreur de serveur';

  @override
  String get networkError => 'Erreur réseau. Veuillez vérifier votre connexion.';
}
