// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MonAutoShop';

  @override
  String get login => 'Connexion';

  @override
  String get companyCode => 'Code entreprise';

  @override
  String get userId => 'ID utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get invalidCompanyCode => 'Code entreprise invalide';

  @override
  String get pleaseEnterCompanyCode => 'Veuillez entrer le code entreprise';

  @override
  String get pleaseEnterUserId => 'Veuillez entrer l\'ID utilisateur';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer le mot de passe';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String get loginSuccess => 'Connexion réussie';

  @override
  String get challan => 'Bon de livraison';

  @override
  String get pendingChallan => 'Bon en attente';

  @override
  String get retailIncentive => 'Incitation au détail';

  @override
  String get loadingChallans => 'Chargement des bons...';

  @override
  String get failedToLoadChallans => 'Échec du chargement des bons';

  @override
  String get noChallansFound => 'Aucun bon trouvé';

  @override
  String get pullToRefresh => 'Tirez pour actualiser ou vérifiez plus tard';

  @override
  String get date => 'Date';

  @override
  String get challanDate => 'Date du bon';

  @override
  String get expectedDeliveryDate => 'Date de livraison prévue';

  @override
  String get challanNo => 'Numéro de bon';

  @override
  String get customerName => 'Nom du client';

  @override
  String get action => 'Action';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get refresh => 'Actualiser';

  @override
  String get showDate => 'Afficher la date:';

  @override
  String get expectedDelivery => 'Livraison prévue';

  @override
  String records(int count, String plural) {
    return '$count enregistrement$plural';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get languageChanged => 'Langue modifiée avec succès';

  @override
  String get home => 'Accueil';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Déconnexion';

  @override
  String get confirmLogout => 'Êtes-vous sûr de vouloir vous déconnecter?';

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
  String get serverError => 'Erreur serveur';

  @override
  String get networkError =>
      'Erreur réseau. Veuillez vérifier votre connexion.';
}
