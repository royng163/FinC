//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <currency_converter_pro/currency_converter_pro_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) currency_converter_pro_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "CurrencyConverterProPlugin");
  currency_converter_pro_plugin_register_with_registrar(currency_converter_pro_registrar);
}
