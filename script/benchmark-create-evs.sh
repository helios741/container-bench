#!/bin/bash

DEPLOY_NUM=1
POD_NUM=500
BASE_NAME=sina-test
NAMESPACE=sina-test
TEMPLATE_FILE=pod.json

function createPvc(){
    id=${1}
    podName="${BASE_NAME}-${id}"
    pod=${pod//EVS_PVC_NAME/${podName}}
    curl -k -X POST -H "Content-Type:application/json" -H "X-Auth-Token:${token}" $endpoint/api/v1/namespaces/${NAMESPACE}/persistentvolumeclaims -d "${pod}" -s 2>&1 >> /tmp/curl-create-pvc.log
}

function createPods(){
    for i in $(seq 1 ${DEPLOY_NUM});do
        createPvc ${i} &
    done
}

function checkPodsCreate(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${TOTAL_POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pvc | grep ${BASE_NAME}| grep -v "NAME"| wc -l`
    done
    echo "All pvc created:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function checkPodsRunning(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${TOTAL_POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pvc | grep ${BASE_NAME}| grep -v "NAME" | grep  "Bound" | wc -l`
    done
    echo "All pvc Bound:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

SCRIPT=$(basename $0)
while test $# -gt 0; do
    case $1 in
        -h | --help)
            echo "${SCRIPT} - for create pod benchmark"
            echo " "
            echo "     options:"
            echo "     -h, --help            show brief help"
            echo "     --deploy-num          set deploy number to create. Default: 1"
            echo "     --name                set pod base name, will use this name and id to generate pod name. Default: sina-test"
            echo "     --namespace           set namespace to create pod, this namespace should already created. Default: sina-test"
            echo "     --pod-template        the file path of pod template in json format"
            echo ""
            exit 0
            ;;
        --name)
            BASE_NAME=${2}
            shift 2
            ;;
        --namespace)
            NAMESPACE=${2}
            shift 2
            ;;
        --pod-template)
            TEMPLATE_FILE=${2}
            shift 2
            ;;
        --deploy-num)
            DEPLOY_NUM=${2}
            shift 2
            ;;
        *)
            echo "unknown option: $1 $2"
            exit 1
            ;;
        esac
done

POD_TEMPLATE=`cat ${TEMPLATE_FILE} | sed "s/^[ \t]*//g"| sed ":a;N;s/\n//g;ta"`
pod=${POD_TEMPLATE//NAMESPACE/${NAMESPACE}}
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createPods
TOTAL_POD_NUM=$(( DEPLOY_NUM * 1 ))
checkPodsCreate
checkPodsRunning
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"
