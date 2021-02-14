#include "mruby/uri_parser.h"
#include "mrb_uri_parser.h"

#if (__GNUC__ >= 3) || (__INTEL_COMPILER >= 800) || defined(__clang__)
# define likely(x) __builtin_expect(!!(x), 1)
# define unlikely(x) __builtin_expect(!!(x), 0)
#else
# define likely(x) (x)
# define unlikely(x) (x)
#endif

#define MRB_URI_PARSED (mrb_class_get_under(mrb, mrb_module_get(mrb, "URI"), "Parsed"))

static mrb_value
mrb_http_parser_parse_url(mrb_state *mrb, mrb_value self)
{
  mrb_value uri_string;
  mrb_bool is_connect = FALSE;

  mrb_get_args(mrb, "S|b", &uri_string, &is_connect);

  struct http_parser_url parser;
  http_parser_url_init(&parser);
  enum http_parser_url_rcs rc = http_parser_parse_url(RSTRING_PTR(uri_string), RSTRING_LEN(uri_string), is_connect, &parser);
  switch (rc) {
    case URL_OKAY: {
      mrb_value argv[UF_MAX + 1] = {mrb_nil_value()};
      if (parser.field_set & (1 << UF_SCHEMA)) {
        argv[UF_SCHEMA] = mrb_str_substr(mrb, uri_string, parser.field_data[UF_SCHEMA].off, parser.field_data[UF_SCHEMA].len);
      }
      if (likely(parser.field_set & (1 << UF_HOST))) {
        argv[UF_HOST] = mrb_str_substr(mrb, uri_string, parser.field_data[UF_HOST].off, parser.field_data[UF_HOST].len);
      }
      if (parser.field_set & (1 << UF_PORT)) {
        argv[UF_PORT] = mrb_fixnum_value(parser.port);
      } else if (mrb_string_p(argv[UF_SCHEMA])) {
        mrb_value schema = mrb_funcall(mrb, argv[UF_SCHEMA], "downcase", 0);
        errno = 0;
        struct servent *answer = getservbyname(mrb_string_value_cstr(mrb, &schema), NULL);
        if (answer != NULL) {
          argv[UF_PORT] = mrb_fixnum_value(ntohs(answer->s_port));
        } else if (errno) {
          mrb_sys_fail(mrb, "getservbyname");
        }
      }
      if (parser.field_set & (1 << UF_PATH)) {
        argv[UF_PATH] = mrb_str_substr(mrb, uri_string, parser.field_data[UF_PATH].off, parser.field_data[UF_PATH].len);
      }
      if (parser.field_set & (1 << UF_QUERY)) {
        argv[UF_QUERY] = mrb_str_substr(mrb, uri_string, parser.field_data[UF_QUERY].off, parser.field_data[UF_QUERY].len);
      }
      if (parser.field_set & (1 << UF_FRAGMENT)) {
        argv[UF_FRAGMENT] = mrb_str_substr(mrb, uri_string, parser.field_data[UF_FRAGMENT].off, parser.field_data[UF_FRAGMENT].len);
      }
      if (parser.field_set & (1 << UF_USERINFO)) {
        argv[UF_USERINFO] = mrb_str_substr(mrb, uri_string, parser.field_data[UF_USERINFO].off, parser.field_data[UF_USERINFO].len);
      }
      argv[UF_MAX] = uri_string;

      return mrb_obj_new(mrb, MRB_URI_PARSED, sizeof(argv) / sizeof(argv[0]), argv);
    } break;
    case MALFORMED_URL:
      mrb_raise(mrb, E_URI_MALFORMED, "Malformed URL");
      break;
    case HOST_NOT_PRESENT:
      mrb_raise(mrb, E_URI_HOST_NOT_PRESENT, "Host not present");
      break;
    case HOST_NOT_PARSEABLE:
      mrb_raise(mrb, E_URI_HOST_NOT_PARSEABLE, "Host not parseable");
      break;
    case CONNECT_MALFORMED:
      mrb_raise(mrb, E_URI_CONNECT_MALFORMED, "Connect malformed");
      break;
    case PORT_TOO_LARGE:
      mrb_raise(mrb, E_URI_PORT_TOO_LARGE, "Port too large");
      break;
  }
}

static mrb_value
mrb_uri_parser_get_port(mrb_state *mrb, mrb_value self)
{
  char *name, *proto = (char*)"tcp";

  mrb_get_args(mrb, "z|z", &name, &proto);

  errno = 0;
  struct servent *answer = getservbyname(name, proto);
  if (answer != NULL) {
    return mrb_fixnum_value(ntohs(answer->s_port));
  } else if (errno == 0) {
    return mrb_nil_value();
  } else {
    mrb_sys_fail(mrb, "getservbyname");
  }

  return self;
}

// Adopted from http://stackoverflow.com/a/21491633

static const unsigned char encode_rfc3986[] = {
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 45, 46,  0,
   48, 49, 50, 51, 52, 53, 54, 55, 56, 57,  0,  0,  0,  0,  0,  0,
    0, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
   80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90,  0,  0,  0,  0, 95,
    0, 97, 98, 99,100,101,102,103,104,105,106,107,108,109,110,111,
  112,113,114,115,116,117,118,119,120,121,122,  0,  0,  0,126,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
};

static mrb_value
mrb_url_encode(mrb_state *mrb, mrb_value self)
{
  mrb_value url_str;
  mrb_get_args(mrb, "S", &url_str);

  mrb_value encoded_len = mrb_num_mul(mrb, mrb_fixnum_value(RSTRING_LEN(url_str)), mrb_fixnum_value(3));
  if (unlikely(mrb_float_p(encoded_len))) {
    mrb_raise(mrb, E_RANGE_ERROR, "string size too big");
  }

  char *url = RSTRING_PTR(url_str);
  mrb_value url_encoded = mrb_str_new(mrb, NULL, mrb_fixnum(encoded_len));
  char *enc = RSTRING_PTR(url_encoded);
  memset(enc, 0, RSTRING_CAPA(url_encoded));

  for (mrb_int i = 0; i < RSTRING_LEN(url_str); i++) {
    if (encode_rfc3986[(unsigned char)url[i]]) *enc = url[i];
    else sprintf(enc, "%%%02X", url[i]);
    while (*++enc);
  }

  return mrb_str_resize(mrb, url_encoded, enc - RSTRING_PTR(url_encoded));
}

// Adopted from http://stackoverflow.com/a/30895866

static const char decode_rfc3986[] = {
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
     0, 1, 2, 3, 4, 5, 6, 7,  8, 9,-1,-1,-1,-1,-1,-1,
    -1,10,11,12,13,14,15,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,10,11,12,13,14,15,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1
};

static mrb_value
mrb_url_decode(mrb_state *mrb, mrb_value self)
{
  mrb_value encoded_str;
  mrb_get_args(mrb, "S", &encoded_str);

  char *encoded = RSTRING_PTR(encoded_str);
  mrb_value decoded_str = mrb_str_new(mrb, NULL, RSTRING_LEN(encoded_str));
  char *decoded = RSTRING_PTR(decoded_str);

  char c, v1, v2;

  for(mrb_int i = 0; i < RSTRING_LEN(encoded_str); i++) {
    c = encoded[i];
    if(c == '%') {
      if((v1=decode_rfc3986[(unsigned char)encoded[++i]])<0||(v2=decode_rfc3986[(unsigned char)encoded[++i]])<0) {
        return mrb_false_value();
      }
      c = (v1<<4)|v2;
    }
    *decoded++ = c;
  }

  return mrb_str_resize(mrb, decoded_str, decoded - RSTRING_PTR(decoded_str));
}

void
mrb_mruby_uri_parser_gem_init(mrb_state* mrb)
{
#ifdef _WIN32
  WSADATA wsaData;
  errno = 0;
  int err = WSAStartup(MAKEWORD(2, 2), &wsaData);
  if (err != 0) {
    mrb_sys_fail(mrb, "WSAStartup");
  }
#endif
  struct RClass *uri_mod, *uri_error_class;
  uri_mod = mrb_define_module(mrb, "URI");
  uri_error_class = mrb_define_class_under(mrb, uri_mod, "Error", E_RUNTIME_ERROR);
  mrb_define_class_under(mrb, uri_mod, "Malformed", uri_error_class);
  mrb_define_class_under(mrb, uri_mod, "HostNotPresent", uri_error_class);
  mrb_define_class_under(mrb, uri_mod, "HostNotParseable", uri_error_class);
  mrb_define_class_under(mrb, uri_mod, "ConnectMalformed", uri_error_class);
  mrb_define_class_under(mrb, uri_mod, "PortTooLarge", uri_error_class);
  mrb_define_module_function(mrb, uri_mod, "parse", mrb_http_parser_parse_url, MRB_ARGS_ARG(1, 1));
  mrb_define_module_function(mrb, uri_mod, "get_port", mrb_uri_parser_get_port, MRB_ARGS_ARG(1, 1));
  mrb_define_module_function(mrb, uri_mod, "encode", mrb_url_encode, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, uri_mod, "decode", mrb_url_decode, MRB_ARGS_REQ(1));
}


void
mrb_mruby_uri_parser_gem_final(mrb_state* mrb)
{
#ifdef _WIN32
  WSACleanup();
#endif
}
