# Shared by the macOS desktop and lab. Never put pairing tokens in this file.
{
  schemaVersion = 1;
  organization = "kaito4681";
  settings = {
    observability = {
      value = {
        otlpTracesUrl = "";
        otlpMetricsUrl = "";
        otlpLogsUrl = "";
      };
      locked = true;
    };
    enableProviderUpdateChecks = {
      value = false;
      locked = true;
    };
  };
  limits = {
    connect = false;
    telemetry = false;
    updates = {
      mode = "off";
      allowNightly = false;
    };
  };
}
