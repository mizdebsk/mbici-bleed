#!/usr/bin/python3
#-
# Copyright (c) 2021 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Mikolaj Izdebski

import xml.etree.ElementTree as ET
import argparse
from subprocess import Popen, PIPE

def resolve_ref(scm, ref):
    p = Popen(["git", "-C", scm, "rev-parse", ref], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    output, err = p.communicate(b"")
    if p.returncode != 0:
        raise Exception(f'git rev-parse failed with exit code {p.returncode}; stderr: {err}')
    return output.decode().split()[0]

parser = argparse.ArgumentParser()
parser.add_argument("-plan", required=True, help="Path to Build Plan")
parser.add_argument("-scm", default="/home/kojan/tmp/fp", help="SCM base URL")
parser.add_argument("-ref", default="HEAD", help="Default SCM commit or ref")
parser.add_argument("-bleed-jpt", required=True)
parser.add_argument("-bleed-xmvn", required=True)
parser.add_argument("-bleed-xmvngen", required=True)
parser.add_argument("-bleed-jpb", required=True)
parser.add_argument("-lookaside", default="https://src.fedoraproject.org/lookaside/pkgs/rpms", help="Lookaside cache base URL")
args = parser.parse_args()

components = set(element.text for element in ET.parse(args.plan).findall('.//component'))

scms = {}
commits = {}

for component in components:
    scms[component] = f'{args.scm}/{component}'
    commits[component] = resolve_ref(scms[component], args.ref)

commits['javapackages-tools'] = args.bleed_jpt
commits['xmvn'] = args.bleed_xmvn
commits['xmvn-generator'] = args.bleed_xmvngen
commits['javapackages-bootstrap'] = args.bleed_jpb

print(f'<subject>')
for component in sorted(scms.keys()):
    print(f'  <component>')
    print(f'    <name>{component}</name>')
    print(f'    <scm>{scms[component]}</scm>')
    print(f'    <commit>{commits[component]}</commit>')
    print(f'    <lookaside>{args.lookaside}/{component}</lookaside>')
    print(f'  </component>')
print(f'</subject>')
