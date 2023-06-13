final unreleasedTag = 'Unreleased';

/// Check if the changelog is valid
String? checkChangeLog(String oldContent, String newContent) {
  final oldMap = getChangelogMap(oldContent);
  final newMap = getChangelogMap(newContent);

  final oldVersions = oldMap.keys.toList();
  final newVersions = newMap.keys.toList();

  final diffVersionList =
      oldVersions.where((element) => !newVersions.contains(element)).toList();

  final diffVersionList2 =
      newVersions.where((element) => !oldVersions.contains(element)).toList();

  final diff = (diffVersionList + diffVersionList2).toSet().toList();

  if (diff.isNotEmpty) {
    return 'The changelog cannot add or remove versions: $diff';
  }

  final changedVersions = <String>[];

  for (final version in oldVersions) {
    final oldContent = oldMap[version]!;
    final newContent = newMap[version]!;

    if (oldContent != newContent) {
      changedVersions.add(version);
    }
  }

  if (changedVersions.isEmpty) {
    return 'No changelog content changed.';
  }

  if (changedVersions.length > 1) {
    return 'Only one version changelog can be changed at a time: $changedVersions';
  }

  final changedVersion = changedVersions.first;
  if (changedVersion != unreleasedTag) {
    return 'Only $unreleasedTag version changelog can be changed. Current changed version: $changedVersion';
  }

  return null;
}

/// Get the changelog map, key is the version, value is the content.
///
/// The content is trimmed.
Map<String, String> getChangelogMap(String content) {
  final result = <String, List<String>>{};

  final lines = content.trim().split('\n');

  var currentVersion = '';

  for (final line in lines) {
    if (line.startsWith('# ')) {
      final version = line.substring(2).trim();
      currentVersion = version;
      result[version] = [];
    } else if (line.startsWith('## ')) {
      final version = line.substring(3).trim();
      currentVersion = version;
      result[version] = [];
    } else if (line.startsWith('### ')) {
      final version = line.substring(4).trim();
      currentVersion = version;
      result[version] = [];
    } else {
      result[currentVersion]!.add(line);
    }
  }

  return result.map((key, value) => MapEntry(key, value.join('\n').trim()));
}
