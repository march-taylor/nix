{ pkgs, ... }:
let
  gitAskpass = pkgs.writeShellApplication {
    name = "git-askpass";
    runtimeInputs = [ pkgs.zenity ];
    text = ''
      prompt="''${1:-Authentication required}"

      case "$prompt" in
        *[Pp]assword*|*[Pp]assphrase*|*[Tt]oken*)
          exec zenity --password \
            --title="Git authentication" \
            --text="$prompt" \
            --ok-label="Continue" \
            --cancel-label="Cancel"
          ;;
        *)
          exec zenity --entry \
            --title="Git authentication" \
            --text="$prompt" \
            --ok-label="Continue" \
            --cancel-label="Cancel"
          ;;
      esac
    '';
  };
in
{
  programs.ssh.askPassword = "${gitAskpass}/bin/git-askpass";
  environment.variables.GIT_ASKPASS = "${gitAskpass}/bin/git-askpass";
}
