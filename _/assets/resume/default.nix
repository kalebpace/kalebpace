{ pkgs, ... }:
let
  tex = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      scheme-small
      latexmk
      pgf
      nicematrix
      textpos
      isodate
      titlesec
      substr;
  };

  buildInputs = [
    pkgs.coreutils
    tex
  ];
in
{
  packages.default = pkgs.stdenv.mkDerivation {
    name = "resume";
    src = ./.;
    buildInputs = buildInputs;
    phases = [ "unpackPhase" "buildPhase" "installPhase" ];
    buildPhase = ''
      mkdir -p .cache/texmf-var
      env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var

      latexmk -f -interaction=nonstopmode -xelatex \
      resume.tex cv.tex
    '';
    installPhase = ''
      mkdir -p $out/
      cp resume.pdf $out/
      cp cv.pdf $out/
    '';
  };

  devShells.default = with pkgs; mkShell {
    buildInputs = [
      buildInputs
      watchexec
    ];
  };
}
