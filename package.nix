{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  withGst ? true,
  glib,
  gst_all_1,
  ffmpeg,
}:

let
  pname = "torrserver" + (if withGst then "-gst" else "");
  version = "MatriX.147.2";

  system = stdenv.hostPlatform.system;

  sources = {
    x86_64-linux = {
      standard = {
        url = "https://github.com/YouROK/TorrServer/releases/download/${version}/TorrServer-linux-amd64";
        hash = "037awy68haj1s9kmj2vsjji757y7fk9d27bw6glq7wfxbbi1120c"; # UPDATE_HASH_X86_STD
      };
      gst = {
        url = "https://github.com/YouROK/TorrServer/releases/download/${version}/TorrServer-gst-linux-amd64";
        hash = "172ysxfzjgpq3i6n321v0djcjc7zfy3j41xq757cv7bb7zzz2v35"; # UPDATE_HASH_X86_GST
      };
    };
    aarch64-linux = {
      standard = {
        url = "https://github.com/YouROK/TorrServer/releases/download/${version}/TorrServer-linux-arm64";
        hash = "0wb8sxm7ln2nfw2n3i9ncfmd7y8zvyg6i1jdbd85qajx89n4lc6r"; # UPDATE_HASH_ARM_STD
      };
      gst = {
        url = "https://github.com/YouROK/TorrServer/releases/download/${version}/TorrServer-gst-linux-arm64";
        hash = "16bm7mni4va1ybimpl6wkkqmh87jrrhxygwq9wxjy4xdnq6xf3zq"; # UPDATE_HASH_ARM_GST
      };
    };
  };

  selectedSource =
    (sources.${system} or (throw "Неподдерживаемая архитектура: ${system}"))
    .${if withGst then "gst" else "standard"};

  gstPackages =
    if withGst then
      [
        glib
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
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

  buildInputs = [ stdenv.cc.cc.lib ] ++ gstPackages;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/TorrServer
    chmod +x $out/bin/TorrServer

    runHook postInstall
  '';

  postInstall = lib.optionalString withGst ''
    mkdir -p $out/libexec
    ln -s ${gst_all_1.gst-plugins-base}/bin/gst-discoverer-1.0 $out/libexec/gst-discoverer

    wrapProgram $out/bin/TorrServer \
      --prefix PATH : "${
        lib.makeBinPath [
          gst_all_1.gst-plugins-base
          ffmpeg
        ]
      }:$out/libexec" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath gstPackages}" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${
        lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPackages
      }"
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
