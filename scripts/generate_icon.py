#!/usr/bin/env python3


# install fontforge from your package manager and not the gui version
# assumes that the script is being ran in the base directory of the mobile repo
# also assumes that lila in present in previous directory

import fontforge
import os

input_directory = "../lila/public/images/fide-fed"
output_font_file = "assets/fonts/FederationIcons.ttf"


font = fontforge.font()

# Set font properties (adjust as needed)
font.fontname = "Federation Icons"
font.fullname = "FIDE Federation Icons"
font.familyname = "LichessFederationIcons"

# unicode private area start index
unicode_code_point = 0xE000

for filename in os.listdir(input_directory):
    if filename.endswith(".svg"):
        svg_file_path = os.path.join(input_directory, filename)

        glyph_name = os.path.splitext(filename)[0]
        glyph = font.createChar(unicode_code_point, glyph_name)

        glyph.importOutlines(svg_file_path)

        # This centers the svg inside the glyph otherwide it is off center
        bounding_box = glyph.boundingBox()
        glyph.width = round(bounding_box[2])
        glyph.left_side_bearing = round((glyph.width - bounding_box[2]) / 2 )

        unicode_code_point += 1

font.generate(output_font_file)

font.close()

dart_output_file = "lib/src/styles/federation_icons.dart"

# Dart code template for the icon data
icon_data_template = """\
'{icon_name}' : IconData(0x{unicode_code_point}, fontFamily: _kFontFam, fontPackage: _kFontPkg),
"""

unicode_code_point = 0xE000

dart_code_list = []

for filename in os.listdir(input_directory):
    if filename.endswith(".svg"):
        icon_name = os.path.splitext(filename)[0]

        icon_data_code = icon_data_template.format(
            icon_name=icon_name,
            unicode_code_point=hex(unicode_code_point)[2:],  # Convert to hexadecimal without '0x' prefix
        )

        dart_code_list.append(icon_data_code)

        unicode_code_point += 1

dart_code = f"""\
import 'package:flutter/widgets.dart';

const _kFontFam = 'LichessFederationIcons';
const String? _kFontPkg = null;

const federationIcons = {{
{"".join(dart_code_list)}
}};
"""

with open(dart_output_file, "w") as output_file:
    output_file.write(dart_code)

print(f"Dart code has been written to {dart_output_file}")
