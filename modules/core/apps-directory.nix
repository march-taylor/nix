{ settings, ... }:
{
  systemd.tmpfiles.rules = [
    "d /srv/apps 0755 ${settings.username} users -"
    "Z /srv/apps - ${settings.username} users -"
  ];
}
