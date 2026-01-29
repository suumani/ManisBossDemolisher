-- __ManisBossDemolisher__/settings.lua
data:extend({
  {
    type = "string-setting",
    name = "manisbossdemolisher-logger-level",
    setting_type = "runtime-global",
    default_value = "debug",
    allowed_values = { "off", "error", "warn", "info", "debug" },
    order = "z[manisbossdemolisher]-a[logger]-a[level]"
  },
  {
    type = "bool-setting",
    name = "manisbossdemolisher-logger-to-log",
    setting_type = "runtime-global",
    default_value = true,
    order = "z[manisbossdemolisher]-a[logger]-b[to-log]"
  },
  {
    type = "bool-setting",
    name = "manisbossdemolisher-logger-to-print",
    setting_type = "runtime-global",
    default_value = true,
    order = "z[manisbossdemolisher]-a[logger]-c[to-print]"
  },
  {
    type = "bool-setting",
    name = "manisbossdemolisher-logger-to-file",
    setting_type = "runtime-global",
    default_value = false,
    order = "z[manisbossdemolisher]-a[logger]-d[to-file]"
  }
})