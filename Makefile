# $Id: Makefile,v 1.1 2007/10/25 18:48:11 carregal Exp $

CONFIG= ./config

include $(CONFIG)

ROOT_LUAS = src/shake/shake.lua 
SHAKE_LUAS= src/shake/grammar.lua src/shake/parser.lua src/shake/scanner.lua src/shake/stir.lua src/shake/util.lua
WEBS= web/shake.lp
CSS= web/css/shake.css

install:
	mkdir -p $(LUA_DIR)/shake
	cp $(ROOT_LUAS) $(LUA_DIR)
	cp $(SHAKE_LUAS) $(LUA_DIR)/shake


