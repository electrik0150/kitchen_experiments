#ifndef CGI_H
#define CGI_H

#include "httpd.h"

int cgiLed(HttpdConnData *connData);
int cgiLight(HttpdConnData *connData);
void tplLed(HttpdConnData *connData, char *token, void **arg);
int cgiReadFlash(HttpdConnData *connData);
void tplCounter(HttpdConnData *connData, char *token, void **arg);

int cgiKcs(HttpdConnData *connData);
void kcsLoader(HttpdConnData *connData, char *token, void **arg);

#endif
