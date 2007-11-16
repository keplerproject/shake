# $Id: Makefile,v 1.3 2007/11/16 16:50:21 carregal Exp $

CONFIG= ./config

include $(CONFIG)
SHAKE_BIN = src/bin/shake
ROOT_LUAS = src/shake/shake.lua 
SHAKE_LUAS= src/shake/grammar.lua src/shake/parser.lua src/shake/scanner.lua src/shake/stir.lua src/shake/util.lua
APP_FILES = src/apps/shake/helper.lua src/apps/shake/init.lua src/apps/shake/shake_suite.lp src/apps/shake/shake.lp
APP_CSS = src/apps/shake/css/doc.css src/apps/shake/css/shake.css
APP_IMG = src/apps/shake/img/shake.gif  

install:
	mkdir -p $(LUA_DIR)/shake
	cp $(ROOT_LUAS) $(LUA_DIR)
	cp $(SHAKE_LUAS) $(LUA_DIR)/shake
	cp $(SHAKE_BIN) $(SYS_BINDIR)
	
install_app:
	mkdir -p $(CGILUA_APPSDIR)/shake
	mkdir -p $(CGILUA_APPSDIR)/shake/css
	mkdir -p $(CGILUA_APPSDIR)/shake/img
	cp $(APP_FILES) $(CGILUA_APPSDIR)/shake
	cp $(APP_CSS) $(CGILUA_APPSDIR)/shake/css
	cp $(APP_IMG) $(CGILUA_APPSDIR)/shake/img