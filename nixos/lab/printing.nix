{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    startWhenNeeded = false;
    drivers = [ pkgs.fxlinuxprint ];

    # 受信は既存の trustedInterfaces (Tailscale) に限定する。
    listenAddresses = [ "*:631" ];
    openFirewall = false;
    allowFrom = [
      "localhost"
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
    defaultShared = true;
    extraConf = ''
      ServerAlias lab
    '';
  };

  hardware.printers = {
    ensureDefaultPrinter = "docuprint-c3450d";
    ensurePrinters = [
      {
        name = "docuprint-c3450d";
        description = "Fuji Xerox DocuPrint C3450 d";
        location = "Lab (10.0.87.31)";
        deviceUri = "socket://10.0.87.31:9100";
        # PDF を XPJL で包む Fuji Xerox ドライバー。PostScript ROM は不要。
        model = "fxlinuxprint.ppd.gz";
        ppdOptions = {
          PageSize = "A4";
          "printer-is-shared" = "true";
          "printer-error-policy" = "retry-job";
        };
      }
    ];
  };
}
