String resolveSwadishtAssetPath(String path) {
  if (path.startsWith('/')) {
    return path.substring(1);
  }
  return path;
}
