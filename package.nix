{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  withGst ? true,
  # Зависимости GStreamer (нужны только при сборке с GST)
  gstreamer ? null,
  gst-plugins-base ? null,
  gst-plugins-good ? null,
  gst-plugins-bad ? null,
  gst-plugins-ugly ? null,
  gst-libav ? null,
  ocl-icd ? null,
}:

let
  pname = "torrserver" + (if withGst then "-gst" else "");
  version = "136";

  system = stdenv.hostPlatform.system;

  tag = "MatriX.v${version}";

  sources = {
    x86_64-linux = {
      standard = {
        url = "https://github.com/YouROK/TorrServer/releases/download/${tag}/TorrServer-linux-amd64";
        hash = "sha256-0000000000000000000000000000000000000000000="; # UPDATE_HASH_X86_STD
      };
      gst = {
        url = "https://github.com/YouROK/TorrServer/releases/download/${tag}/TorrServer-gst-linux-amd64";
        hash = "sha256-0000000000000000000000000000000000000000000="; # UPDATE_HASH_X86_GST
      };
    };
    aarch64-linux = {
      standard = {
        url = "https://github.com/YouROK/TorrServer/releases/download/${tag}/TorrServer-linux-arm64";
        hash = "sha256-0000000000000000000000000000000000000000000="; # UPDATE_HASH_ARM_STD
      };
      gst = {
        url = "https://github.com/YouROK/TorrServer/releases/download/${tag}/TorrServer-gst-linux-arm64";
        hash = "sha256-0000000000000000000000000000000000000000000="; # UPDATE_HASH_ARM_GST
      };
    };
  };

  selectedSource =
    (sources.${system} or (throw "Неподдерживаемая архитектура: ${system}"))
    .${if withGst then "gst" else "standard"};

  gstLibs =
    if withGst then
      [
        gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
        ocl-icd
      ]
    else
      [ ];

in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = selectedSource.url;
    sha256 = selectedSource.hash;
  };

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ] ++ lib.optionals withGst [ makeWrapper ];

  buildInputs = [ stdenv.cc.cc.lib ] ++ gstLibs;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/TorrServer
    chmod +x $out/bin/TorrServer

    ${lib.optionalString withGst ''
      wrapProgram $out/bin/TorrServer \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath gstLibs}" \
        --prefix PATH : "${
          lib.makeBinPath [
            gstreamer
            gst-plugins-base
          ]
        }"
    ''}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Torrent stream server" + (if withGst then " (с поддержкой GStreamer)" else "");
    homepage = "https://github.com/YouROK/TorrServer";
    license = licenses.gpl3Only;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "TorrServer";
  };
}
