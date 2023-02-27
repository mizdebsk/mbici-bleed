#!/bin/sh
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

set -eu

plan=/home/kojan/git/mbici-config/plan/bootstrap-all-rawhide.xml
platform=/home/kojan/git/mbici-config/platform/rawhide-jdk.xml
resultDir=/mnt/nfs/mbi-result/local
cacheDir=/mnt/nfs/mbi-cache
workDir=/tmp
PATH=$PATH:/home/kojan/git/mbici-workflow/target

reportDir=/mnt/nfs/redhat/scratch/mizdebsk/bleed

rm -rf test/
mkdir test

echo === Generating Test Subject from PRs... >&2
./local-subject-bleed.py -bleed-jpt $1 -bleed-xmvn $2 -bleed-jpb $3 -plan "$plan" >test/subject.xml

echo === Generating Workflow... >&2
mbici-wf generate -plan "$plan" \
     -platform "$platform" \
     -subject test/subject.xml \
     -workflow test/workflow.xml \
#     -validate

echo === Generating initial report... >&2
rm -rf $reportDir
mbici-wf report \
     -plan "$plan" \
     -platform "$platform" \
     -subject test/subject.xml \
     -workflow test/workflow.xml \
     -resultDir "$resultDir" \
     -reportDir $reportDir

echo === Running Workflow... >&2
mbici-wf run \
     -kubernetesNamespace mbici-local \
     -maxCheckoutTasks 10 \
     -maxSrpmTasks 500 \
     -maxRpmTasks 200 \
     -maxValidateTasks 20 \
     -workflow test/workflow.xml \
     -resultDir "$resultDir" \
     -cacheDir "$cacheDir" \
     -workDir "$workDir"

echo === Generating final report... >&2
#rm -rf $reportDir
mbici-wf report \
     -plan "$plan" \
     -platform "$platform" \
     -subject test/subject.xml \
     -workflow test/workflow.xml \
     -resultDir "$resultDir" \
     -reportDir $reportDir
