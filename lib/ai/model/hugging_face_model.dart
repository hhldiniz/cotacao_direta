/// One file of a model repository on Hugging Face, pinned by its SHA-256.
class HuggingFaceFile {
  /// Path inside the repository, e.g. `model.safetensors`.
  final String path;

  /// Expected SHA-256 of the content, in lowercase hex. A download that does
  /// not match is thrown away.
  final String sha256;

  /// Size in bytes, for the progress bar and the size shown on screen.
  final int size;

  const HuggingFaceFile(
      {required this.path, required this.sha256, required this.size});
}

/// A model published on Hugging Face, pinned to one commit of its repository.
///
/// Pinning the revision (and the hashes) means the app always downloads
/// exactly the bytes it was tested with: a later push to the repository can
/// neither change the forecasts nor slip something else in.
class HuggingFaceModel {
  /// `owner/name` of the repository.
  final String repository;

  /// Full commit hash the files are downloaded from.
  final String revision;

  /// Name shown on screen.
  final String displayName;

  /// SPDX identifier of the model's license.
  final String license;

  final HuggingFaceFile config;
  final HuggingFaceFile weights;

  const HuggingFaceModel({
    required this.repository,
    required this.revision,
    required this.displayName,
    required this.license,
    required this.config,
    required this.weights,
  });

  List<HuggingFaceFile> get files => [config, weights];

  int get totalSize => config.size + weights.size;

  /// Download address of [file] at the pinned revision. Hugging Face answers
  /// with a redirect to its CDN; both send CORS headers, so the web build can
  /// download it too.
  Uri urlOf(HuggingFaceFile file) =>
      Uri.https("huggingface.co", "/$repository/resolve/$revision/${file.path}");

  /// Page of the repository, for the credits.
  Uri get pageUrl => Uri.https("huggingface.co", "/$repository");

  /// Folder the files are kept in on the device. The revision is part of it,
  /// so moving to a new revision never mixes files of two versions.
  String get storageFolder =>
      "${repository.replaceAll("/", "--")}/${revision.substring(0, 12)}";

  /// Chronos-Bolt Tiny, by Amazon: a 9M-parameter time-series foundation
  /// model (T5 encoder-decoder), Apache-2.0. Small enough — 35 MB and tens of
  /// milliseconds per forecast on a phone CPU — to run on practically any
  /// device in use today, from entry-level Android phones to the browser.
  static const chronosBoltTiny = HuggingFaceModel(
    repository: "amazon/chronos-bolt-tiny",
    revision: "a0e552de83495b5c28c14c71c374f3e33280b340",
    displayName: "Chronos-Bolt Tiny",
    license: "Apache-2.0",
    config: HuggingFaceFile(
      path: "config.json",
      sha256:
          "278f0086733031635fb1c861cb01c1bad6477420c7fcb19381a2993e335785e0",
      size: 1120,
    ),
    weights: HuggingFaceFile(
      path: "model.safetensors",
      sha256:
          "75068728d376d2bec670379eeef4bfb4d24c0cfe24d957451f8d19b447030a32",
      size: 34622352,
    ),
  );
}
