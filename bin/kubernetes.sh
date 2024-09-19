# !/bin/bash

# TODO bylo by fajn znát zda-li buildovaná verze byla shodná snazaním -> není vhodné v tomto případě použít SemVer
#      zde zní ale otázka jak udržovat, nebo kde se rozhodovat co to je za verzi dle namespacu,
#      neměla by se v tomto případě měnit verze je při stage? tj vzít poslední stage version

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

cd $SCRIPT_DIR/..

echo "===================== START definice prostředí ====================="
stageType=$1
if [[ $stageType == 'd' ]]; then
    NAMESPACE='development'
elif [[ $stageType == 'p' ]]; then
    NAMESPACE='production'
elif [[ $stageType == 's' ]]; then
    NAMESPACE='staging'
else
    echo 'U have to run with the argument (d)evelopment / (s)tage / (p)roduction'
    exit
fi

overlayPath=./kubernetes/overlays/$NAMESPACE
applyDir=./kubernetes/out/$NAMESPACE

if [ ! -d $applyDir ]; then
    mkdir -p $applyDir
fi

echo "stageType=$stageType"
echo "NAMESPACE=$NAMESPACE"
echo "overlayPath=$overlayPath"
echo "applyDir=$applyDir"
echo "===================== KONEC definice prostředí ====================="

echo "===================== START zpracování env file ====================="
envCustom="./env/$NAMESPACE.env"
envTemplate="./env/env.template"

if [ ! -f "${envCustom}" ]; then
    cp ${envTemplate} $envCustom
elif [ -f .env ]; then
    cat $envCustom >tmp0
    cat $envTemplate >>tmp0
    awk -F "=" '!a[$1]++' tmp0 >tmp1 && mv tmp1 $envCustom && rm tmp0
fi

echo "envCustom=$envCustom"
echo "envTemplate=$envTemplate"
echo "===================== KONEC zpracování env file ====================="

echo "===================== START zpracování čísla verze ====================="
### ve výsledku verzování není důležité jako číslo, spíše je zde jen jako ulechčení pro hrání s minikubeme
export APP_IMAGE_VERSION=$(/bin/bash ./bin/version.sh -papp -vbug -f${envCustom})
export NGINX_IMAGE_VERSION=$(/bin/bash ./bin/version.sh -pnginx -vbug -f${envCustom})
sed -i "s/APP_IMAGE_VERSION=.*/APP_IMAGE_VERSION=${APP_IMAGE_VERSION}/g" $envCustom
sed -i "s/NGINX_IMAGE_VERSION=.*/NGINX_IMAGE_VERSION=${NGINX_IMAGE_VERSION}/g" $envCustom

echo "APP_IMAGE_VERSION=$APP_IMAGE_VERSION"
echo "NGINX_IMAGE_VERSION=$NGINX_IMAGE_VERSION"
echo "===================== KONEC zpracování čísla verze ====================="

echo "===================== START načti env vars, slož names pro image ====================="
export $(grep -v '^#' ${envCustom} | xargs -d '\n')
export NGINX_SERVER_NAME=$NAMESPACE.$NGINX_HOST_NAME
export APP_IMAGE=$IMAGE_PREFIX/$APP_NAME:$APP_IMAGE_VERSION
export NGINX_IMAGE=$IMAGE_PREFIX/"nginx":$NGINX_IMAGE_VERSION

echo "NGINX_SERVER_NAME=$NGINX_SERVER_NAME"
echo "APP_IMAGE=$APP_IMAGE"
echo "NGINX_IMAGE=$NGINX_IMAGE"
echo "===================== KONEC načti env vars, slož names pro image ====================="

echo "===================== START přepis env dle vars, a vytvoř final ====================="
sed -i "s/NGINX_SERVER_NAME=.*/NGINX_SERVER_NAME=${NGINX_SERVER_NAME}/g" $envCustom
cp $envCustom ./.env
echo "$envCustom > ./.env"
echo "===================== KONEC přepis env dle vars, a vytvoř final ====================="

echo "===================== START minikube ====================="
if minikube status | grep -q "Running"; then
    echo "# minikube: is up"
else
    echo "# minikube: is down"
    minikube start
    minikube addons enable ingress
    minikube addons enable metrics-server
fi
echo "===================== END minikube ====================="

echo "===================== START docker ====================="
eval $(minikube docker-env)
### možná dobrý point, když už to takto stavím jestli není vhodné použít i suffix pro env i pro out yaml podle namespacu a zároveň s tím jej vložit do adr docker
docker compose convert >docker-compose-out.yaml
### todo lze ověřit zda-li dokcer compose build, byl proveden správně? mímo čtení jeho vlastních logu
### docker build je schopen vrátit int 1 jako success umí toto compose
docker compose -fdocker-compose-out.yaml build #--no-cache
echo "===================== END docker ====================="

echo "===================== START envsubst, kustomize, kubectl ====================="
### pozor jsou použity v kustomize proměnné pro jednodušší naplnění, pokud by bylo na produkci není plněno z envu!
### proto dělám trik převedení na tmp a následně convertu envsubst build
### pozor poukud jsou použity env proměnné již nad secret, tak použití po vytvoření manifestu je již pozdě zaměňovat
rm -f $applyDir/*.yaml
envsubst <$envCustom <$overlayPath/kustomization.template >$overlayPath/kustomization.yaml
kustomize build $overlayPath/ -o $applyDir/

### fishy mohlo by se jistě použít jednodušeji
# ano toto je možnost, ale, není vhodné je vhodné oddělit manifest kustomoize od envu
# od doby co je definice celá v kustomize je jendodušší použít přímo envsubst na kustomize.yaml a zpracovat jej jako out a na něj aplikovat kustomize
# naplnění output yamlu env proměnnýma
# převedení specifickych hodnot do base64 pomoci sedu
for file in $applyDir/*.yaml; do
    envsubst <$envCustom <$file >tmpFile
    mv tmpFile $file
done

kubectl apply -f $overlayPath/../namespaces.yaml
kubectl apply -f $applyDir/

echo "finished"
echo "===================== END envsubst, kustomize, kubectl ====================="
