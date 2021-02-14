#ifndef MRUBY_URI_PARSER_H
#define MRUBY_URI_PARSER_H

#include <mruby.h>

MRB_BEGIN_DECL

#define E_URI_ERROR (mrb_class_get_under(mrb, mrb_module_get(mrb, "URI"), "Error"))
#define E_URI_MALFORMED (mrb_class_get_under(mrb, mrb_module_get(mrb, "URI"), "Malformed"))
#define E_URI_HOST_NOT_PRESENT (mrb_class_get_under(mrb, mrb_module_get(mrb, "URI"), "HostNotPresent"))
#define E_URI_HOST_NOT_PARSEABLE (mrb_class_get_under(mrb, mrb_module_get(mrb, "URI"), "HostNotParseable"))
#define E_URI_CONNECT_MALFORMED (mrb_class_get_under(mrb, mrb_module_get(mrb, "URI"), "ConnectMalformed"))
#define E_URI_PORT_TOO_LARGE (mrb_class_get_under(mrb, mrb_module_get(mrb, "URI"), "PortTooLarge"))

MRB_END_DECL

#endif
