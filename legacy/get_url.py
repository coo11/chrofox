# -*- coding: utf-8 -*-

import requests
import re
from pathlib import Path

version = [{"arch": "x86", "ap": "-multi-chrome"},
           {"arch": "x64", "ap": "x64-stable-multi-chrome"}]


def post(arch, ap):
    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<request protocol="3.0" version="1.3.23.9" shell_version="1.3.21.103" ismachine="0" sessionid="{{3597644B-2952-4F92-AE55-D315F45F80A5}}" installsource="ondemandcheckforupdate" requestid="{{CD7523AD-A40D-49F4-AEEF-8C114B804658}}" dedup="cr">
	<hw sse="1" sse2="1" sse3="1" ssse3="1" sse41="1" sse42="1" avx="1" physmemory="12582912" />
	<os platform="win" version="10.0" arch="{arch}" />
	<app appid="{{8A69D345-D564-463C-AFF1-A69D9E530F96}}" ap="{ap}">
		<updatecheck />
	</app>
</request>"""
    r = requests.post("http://tools.google.com/service/update2", data=xml)
    return r.text


def fetch():
    for i in version:
        arch = i["arch"]
        resp = post(arch, i['ap'])
        url = re.findall('codebase="(https://dl\..*?)"', resp)[0]
        filename = re.findall(r'package\b.*?\bname="(.*?)"', resp)[0]
        re.findall('''pattern''', '''string''',)
        Path('Dist').mkdir(exist_ok=True)
        with open('./Dist/' + arch, 'w', encoding='utf-8') as f:
            f.write(f'{url}{filename}')


fetch()