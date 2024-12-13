#!/bin/sh

SVG_LILA_PATH=../lila/public/images/fide-fed
SVG_MOBILE_PATH=assets/images/fide-fed

dart run vector_graphics_compiler --input-dir $SVG_LILA_PATH --out-dir $SVG_MOBILE_PATH
