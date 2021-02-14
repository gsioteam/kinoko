#ifdef MRB_INT16
#  error "mruby-uri-parser is not compatible with MRB_INT16"
#endif

#ifndef MRB_URI_PARSER_H
#define MRB_URI_PARSER_H
#include <stdio.h>
#include <string.h>
#include "uri_parser.h"
#include <mruby/string.h>
#include <errno.h>
#include <mruby/error.h>
#include <mruby/numeric.h>

#ifdef _WIN32

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")

#else
#include <netdb.h>
#include <arpa/inet.h>
#endif

#endif
