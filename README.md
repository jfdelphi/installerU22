THIS SCRIPTS ARE NOT GOOD ENOGH .. I WORK ON IT

Goal: Let's pour our heart and soul into creating installers that:

- Work perfectly and exclusively on Ubuntu 22.04 LTS.
- Run smoothly on fresh installations, no matter what.
- Check every prerequisite to ensure nothing breaks.
- Verify success so we can trust everything is in place.
- Capture every error in detailed logs to make troubleshooting easier.

Help: I’m reaching out because I need your support to make this happen!


install with ONE line 
=============================
```
podman
sudo wget -qO- https://raw.githubusercontent.com/jfdelphi/installerU22/refs/heads/main/install-podman.sh | bash

graylog
sudo wget -qO- https://raw.githubusercontent.com/jfdelphi/installerU22/refs/heads/main/install_graylog_podman.sh | bash

activate syslog (to UDP 10.88.0.184 fixed currently)
sudo wget -qO- https://raw.githubusercontent.com/jfdelphi/installerU22/main/install_syslog514udp.sh  | bash

add show computerinfo on startup
sudo wget -qO- https://raw.githubusercontent.com/jfdelphi/installerU22/main/install_showComputerinfo.sh   | bash

```
