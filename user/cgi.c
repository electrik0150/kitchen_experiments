/*
Some random cgi routines. Used in the LED example and the page that returns the entire
flash as a binary. Also handles the hit counter on the main page.
*/

/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */


#include <string.h>
#include <osapi.h>
#include "user_interface.h"
#include "mem.h"
#include "httpd.h"
#include "cgi.h"
#include "io.h"
#include <ip_addr.h>
#include "espmissingincludes.h"

#include <stdout.c>

//cause I can't be bothered to write an ioGetLed()
static char currLedState=0;

//Cgi that turns the LED on or off according to the 'led' param in the POST data
int ICACHE_FLASH_ATTR cgiLed(HttpdConnData *connData) {
	int len;
	char buff[1024];
	
	if (connData->conn==NULL) {
		//Connection aborted. Clean up.
		return HTTPD_CGI_DONE;
	}

	len=httpdFindArg(connData->postBuff, "led", buff, sizeof(buff));
	if (len!=0) {
		currLedState=atoi(buff);
		ioLed(currLedState);
	}

	httpdRedirect(connData, "led.tpl");
	return HTTPD_CGI_DONE;
}

static long sliderValues=0;
static char part1[] = "CONNECT  '74F0-6D-CCF915' ";
static char part2[] = "0FUCK!";
static char part3[] = "DISCONNECT  '74F0-6D-CCF915'\0";

static void SendUartData (char *data, int length) {
	for (int i = 0; i < length; ++i) {
		stdoutUartTxd(data[i]);
	}
}

//Cgi that should change the light status according to the 'light' param in the POST data
int ICACHE_FLASH_ATTR cgiLight(HttpdConnData *connData) {
	int len;
	char buff[1024];
	unsigned char Red, Green, Blue, White;

	if (connData->conn==NULL) {
		//Connection aborted. Clean up.
		return HTTPD_CGI_DONE;
	}

	len=httpdFindArg(connData->postBuff, "light", buff, sizeof(buff));
	if (len!=0) {
		sliderValues=atoi(buff);
	}
	Red=(char)((sliderValues&0x000000ff)>>0);
	Green=(char)((sliderValues&0x0000ff00)>>8);
	Blue=(char)((sliderValues&0x00ff0000)>>16);
	White=(char)((sliderValues&0xff000000)>>24);

	part2[1]=Red;
	part2[2]=Green;
	part2[3]=Blue;
	part2[4]=White;
	part2[5]=0xFF;

	SendUartData(part1, strlen(part1));
	SendUartData(part2, 6);
	SendUartData(part3, strlen(part3));

	httpdRedirect(connData, "index.tpl");
	return HTTPD_CGI_DONE;
}

//Template code for the led page.
void ICACHE_FLASH_ATTR tplLed(HttpdConnData *connData, char *token, void **arg) {
	char buff[128];
	if (token==NULL) return;

	os_strcpy(buff, "Unknown");
	if (os_strcmp(token, "ledstate")==0) {
		if (currLedState) {
			os_strcpy(buff, "on");
		} else {
			os_strcpy(buff, "off");
		}
	}
	httpdSend(connData, buff, -1);
}

static long hitCounter=0;

int ICACHE_FLASH_ATTR cgiKcs(HttpdConnData *connData) {
	int len;
	char buff[1024];
	unsigned char Red, Green, Blue, White;

	if (connData->conn==NULL) {
		//Connection aborted. Clean up.
		return HTTPD_CGI_DONE;
	}

	httpdRedirect(connData, "kcs.tpl");
	return HTTPD_CGI_DONE;
}

void ICACHE_FLASH_ATTR kcsLoader(HttpdConnData *connData, char *token, void **arg) {
	char buff[128];
	if (token==NULL) return;

	if (os_strcmp(token, "value")==0) {
		os_sprintf(buff, "%ld", sliderValues);
	}

	httpdSend(connData, buff, -1);
}


//Template code for the counter on the index page.
void ICACHE_FLASH_ATTR tplCounter(HttpdConnData *connData, char *token, void **arg) {
	char buff[128];
	if (token==NULL) return;

	if (os_strcmp(token, "counter")==0) {
		hitCounter++;
		os_sprintf(buff, "%ld", hitCounter);
	}

	if (os_strcmp(token, "value")==0) {
		os_sprintf(buff, "%ld", sliderValues);
	}

	if (os_strcmp(token, "value1")==0) {
		os_sprintf(buff, "%ld", sliderValues & 0x000000FF);
	}

	if (os_strcmp(token, "value2")==0) {
		os_sprintf(buff, "%ld", (sliderValues & 0x0000FF00) >> 8);
	}

	if (os_strcmp(token, "value3")==0) {
		os_sprintf(buff, "%ld", (sliderValues & 0x00FF0000) >> 16);
	}

	if (os_strcmp(token, "value4")==0) {
		os_sprintf(buff, "%ld", (sliderValues & 0xFF000000) >> 24);
	}

	httpdSend(connData, buff, -1);
}


//Cgi that reads the SPI flash. Assumes 512KByte flash.
int ICACHE_FLASH_ATTR cgiReadFlash(HttpdConnData *connData) {
	int *pos=(int *)&connData->cgiData;
	if (connData->conn==NULL) {
		//Connection aborted. Clean up.
		return HTTPD_CGI_DONE;
	}

	if (*pos==0) {
		os_printf("Start flash download.\n");
		httpdStartResponse(connData, 200);
		httpdHeader(connData, "Content-Type", "application/bin");
		httpdEndHeaders(connData);
		*pos=0x40200000;
		return HTTPD_CGI_MORE;
	}
	//Send 1K of flash per call. We will get called again if we haven't sent 512K yet.
	espconn_sent(connData->conn, (uint8 *)(*pos), 1024);
	*pos+=1024;
	if (*pos>=0x40200000+(512*1024)) return HTTPD_CGI_DONE; else return HTTPD_CGI_MORE;
}

