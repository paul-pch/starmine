import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page de création d'une issue du dépôt (spec 16).
const issuesUrl = 'https://github.com/paul-pch/starmine/issues/new';

/// Ouvre la création d'une issue dans le navigateur, version de l'app pré-remplie. Renvoie
/// `false` si aucun navigateur n'a pu l'ouvrir.
Future<bool> reportIssue() async {
  var version = '?';
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } on Object {
    // Version inconnue : le lien reste utile.
  }
  final uri = Uri.parse(issuesUrl).replace(
    queryParameters: {
      'body': 'Version : $version\n\nCe qui se passe :\n\nCe qui était attendu :\n',
    },
  );
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}
