#!/bin/bash
# Based on https://docs.google.com/document/d/1aUUZ1jthRpg4QURIIyzlOaPWlmQzr-jBn3wZipVUPt4/edit

# You'll need Docker installed and running first.

set -Eeuxo pipefail

# Values from https://github.com/TinyTapeout/tt-gds-action/blob/main/action.yml#L18-L22
export OPENLANE_ROOT=$PWD/tt/openlane
export PDK_ROOT=$PWD/tt/pdk
export PDK=sky130A
export OPENLANE_TAG=2023.09.11
export OPENLANE_IMAGE_NAME=efabless/openlane:7e5a2e9fb274c0a100b4859a927adce7089455ff

if [ ! -d tt ]; then
    # TODO: git pull it every time
    git clone -b tt06 https://github.com/TinyTapeout/tt-support-tools tt
    pip install -r tt/requirements.txt
fi

if [ ! -d $OPENLANE_ROOT ]; then
    git clone --depth=1 --branch $OPENLANE_TAG https://github.com/The-OpenROAD-Project/OpenLane.git $OPENLANE_ROOT
    pushd $OPENLANE_ROOT
    make
    popd
fi

# if [ ! -d GDS2glTF ]; then
#     git clone https://github.com/mbalestrini/GDS2glTF
#     pip install -r GDS2glTF/requirements.txt
# fi

./tt/tt_tool.py --create-user-config
./tt/tt_tool.py --harden
./tt/tt_tool.py --create-png

# python GDS2glTF/gds2gltf.py runs/wokwi/results/final/gds/*.gds
# echo "Open https://gds-viewer.tinytapeout.com/?model=https://localhost:8000/tt_um_cchan_chipgpt.gds.gltf to see the results"
# python -m http.server --directory runs/wokwi/results/final/gds/ 8000
# openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem -addext "subjectAltName = IP:127.0.0.1" -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=127.0.0.1"
# python -c 'from http.server import HTTPServer,BaseHTTPRequestHandler as B;import ssl;h=HTTPServer(("localhost",4443),B);h.socket=ssl.wrap_socket(h.socket,keyfile="key.pem",certfile="cert.pem",server_side=True);h.serve_forever()'
