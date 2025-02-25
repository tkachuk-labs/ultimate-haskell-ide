let pkgs22 = import (import ./nixpkgs22.nix) {};
in
{
  pkgs ? pkgs22,
  mini ? true,
  formatter ? "ormolu",
  vimBackground ? "light",
  vimColorScheme ? "PaperColor"
}:
with pkgs;
with builtins;
with lib.lists;

let ignore-patterns = ''
      .git
      .gitignore
      *.nix
      *.sh
      *.md
      LICENSE
      result
    '';
    formatter-registry = {
      ormolu = ''
      let g:brittany_on_save = 0
      let g:ormolu_disable = 0
      '';
      brittany = ''
      let g:brittany_on_save = 1
      let g:ormolu_disable = 1
      '';
      none = ''
      let g:brittany_on_save = 0
      let g:ormolu_disable = 1
      '';
    };
    lesspipeWrapper = writeShellScriptBin "lesspipe" "${lesspipe}/bin/lesspipe.sh";
    vi21src = stdenv.mkDerivation {
      name = "vi21src";
      src = nix-gitignore.gitignoreSourcePure ignore-patterns ./..;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/
        cp -R ./ $out/
      '';
    };
    vi21 = neovim.override {
      viAlias = true;
      vimAlias = true;
      configure = {
        customRC = ''
          set runtimepath+=${vi21src}
          let $PATH.=':${silver-searcher}/bin:${nodejs}/bin:${less}/bin:${lesspipeWrapper}/bin:${python38Packages.grip}/bin:${xdg_utils}/bin:${git}/bin:${jre8}/bin'
          let g:vimBackground = '${vimBackground}'
          let g:vimColorScheme = '${vimColorScheme}'
          let g:languagetool_jar='${languagetool}/share/languagetool-commandline.jar'
          source ${vi21src}/vimrc.vim
          try
            source ~/.ultimate-haskell-ide/vimrc.vim
          catch
          endtry
        '' + (getAttr formatter formatter-registry);
        packages.vim21 = with pkgs.vimPlugins; {
          start = [
            #
            # Interface
            #
            ack-vim
            ctrlp-vim
            vim-fugitive
            vim-gitgutter
            lightline-vim
            vim-togglelist
            papercolor-theme
            vim-better-whitespace
            #
            # Programming
            #
            haskell-vim
            hlint-refactor-vim
            vim-nix
            dhall-vim
            psc-ide-vim
            purescript-vim
            #
            # Productivity
            #
            coc-nvim
            sideways-vim
            vim-LanguageTool
          ];
          opt = [

          ];
        };
      };
    };
in
  if mini
  then vi21
  else {
    #
    # Vi
    #
    vi = vi21;
    #
    # Haskell
    #
    ghc = haskell.compiler.ghc902;
    stack = haskellPackages.stack;
    cabal = cabal-install;
    hlint = haskellPackages.hlint;
    hoogle = haskellPackages.hoogle;
    apply-refact = haskellPackages.apply-refact;
    hspec-discover = haskellPackages.hspec-discover;
    implicit-hie = haskellPackages.implicit-hie;
    ormolu = haskellPackages.ormolu;
    brittany = haskellPackages.brittany;
    inherit zlib haskell-language-server cabal2nix ghcid;
    #
    # Dhall
    #
    inherit dhall dhall-json;
    #
    # Misc
    #
    inherit nix niv git curl;
  }
