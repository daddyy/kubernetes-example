# docker/docker-compose, minikube/kubectl/kompose, gitlab
- základem všeho je vždy sledovat logy při spuštění i v průběhu, je jedno jestli se jedná o docker / docker compose / kubernetes
## docker

- [docker](https://www.docker.com/get-started/), [docker compose](https://docs.docker.com/compose/install/linux/)
- nastavení .env, pozor, nastavení .env je v adresářích docker
```shell
copy .env.template <namespave>.env
```
- pokud chci aby appka naslouhala na konkrétní doméně je nutné doplnit do /etc/hosts => `127.0.0.0  ${NGINX_SERVER_NAME}`, nicméně nginx v konfiguračním souboru je nastaven jako výchozí po spuštění docku se chytne i pod doméneou `localhost`

- kontrola nastavení, po doplnění env

```shell
docker compsoe convert
```

- docker compose se řidí manifestem [docker-compose.yaml](/docker-compose.yaml).
```shell
docker compose up --build
```

- pozor pokud je sližen build s Dockerfile, který je buildován pomoci docker compose je vše v pořádku, pokud je však použit pouze docker je nutné přenést všechny vlastnosti i do dockerfile, jinak je nutné zařidit, aby argumenty, speciální vlastnosti předáváné v docker compose byly inicializovány i v dockerfile

### cheatsheet
- pro definovaný soubor `docker-compose.yaml`
```shell
# ## spustí existujicí služby
docker compose start
# ## zastaví všechny služby
docker compose stop
# ## pozastaví všechny bežící služby
docker compose pause
# ## spustí pozastavené služby
docker compose unpause
# ## zobrazí stav  všech služeb
docker compose ps
# ## spustí všechny služby a pro každou vytvoří container, pro spuštení na pozadí arg -d
docker compose up
# ## zastaví všechny služby a smaže je
docker compose down
# ## smazání kontejnerů, argument --all = všechny
docker compose rm
# ## slouží k odstranění všech kontejnerů, které nejsou použity container|image|volume|network|build
docker prune <resource>
# ## odstraní všechny specifikované zdroje
# ## již na počátku si stanov správný název image / contianeru jinak v tom budeš mít bordel
docker system prune
```
## Dockerfile
- [multistage](/docker/php/Dockerfile)
  - vhodné používat [alias](/docker/php/Dockerfile) pro image
  - final stage vždy na konci
  - vždy platí, čím menší fnal image tím lepší :-)
- pokud možné tak redukujeme buildovaný container, tj vyhnout se zbytečným runum

## minikube / kubectl
- [minikube](https://minikube.sigs.k8s.io/docs/start/), [lens](https://docs.k8slens.dev/getting-started/install-lens/) (jako hobbiest není potřeba licence)

### minikube cheatsheet
```shell
minikube start
minikube status
minikube stop
# ## GUI pro kubernetes, odlechčená verze vůči lens
minikube dashboard
# ## párkrát se mi stalo, že minikube se sekl na localhostu (suspend), bylo nutné smazat vše (nepomohl mi restart služeb)
minikube delete --all
# ## přidávání komponent
minikube addons list
# ## ingress (loadbalancer)
minikube addons enable <name>
# ## stav kubectl
systemctl status kubectl.socket
systemctl status kubectl.service
# ## pokud cheme použít lokální image je nutné v tomto případě setnout docker envs, unset -u
eval $(minikube docker-env)
```

### kubectl cheatcheet
- u kubectl je výborně popsán help i s použitím, tzn. neboj se použít atribut `-h`!
```shell
# ## získání informaci o daném clusteru
kubectl cluster-info
# ## získání infroamcí o zdroji, lze oddělit čátkou a tak získat více zdrojů
kubectl get <resource_name>
kubectl get pods,deployments
# ## smazání zdroje
kubectl delete <resource_name>
# ## získání logu o daném zdroji
kubectl logs <resource_name>
# ## vytvoří zdroj
kubectl create
# ## aplikuje dle definice, než mi to došlo tak mi to trvalo = manifest == s milioy ruznych navodu tomuto kubectl apply ... && kubectl expose
kubectl apply
# ## vystaví již existujicí zdroj proti kubernetí službě
kubectl expose
# ## je schopen spustit příkad nad daným kontejnerem
kubectl exec
# ## zobrazí konkrétní informace o daném zdroji
kubectl describe <resource_name>
```

## docker + kubectl + kompose
- [deploy](/bin/kubernetes.sh)
```shell
├── app # adresář věnovaný pouze aplikaci, kopírujeme jej celý do image je to nutné?
│   ├── vendor # ve stejném kontejneru jako je aplikace beží compose install
│   │   ├── bin
│   │   ├── composer
│   │   └── phpstan
│   │       └── phpstan
│   │           └── conf
│   └── www # adresář který kopírujeme do image nginxu
├── bin # shell commands
├── docker # deifnice pro jednotlivé image pro docker
│   ├── mysql
│   ├── nginx
│   └── php
└── kubernetes # definice pro kubernetes cluster, kde u těchto definic používáme kompose pro zpracování manifestu
    ├── base # základní manifesty dle podů + samostatně configmapy, které mohou být zpracovány pomoci kompose, dle definice kompozition.yaml
    │   ├── configmap
    │   ├── ingress
    │   ├── mysql
    │   └── nginx-php
    ├── out # adresář kam exportujeme manifestu které budeme aplikovat nad clusterem
    └── overlays # přepisy manifestu v base pro jednotlivé namespace
        ├── development
        ├── production
        └── staging
```

```shell
# production.learning.daddyy
./bin/deploy.sh p
# development.learning.daddyy
./bin/deploy.sh d
# staging.learning.daddyy
./bin/deploy.sh s
```

## kompose
- `patchesStrategicMerge` = slouží k doplnění sjednocenní manifestů (manifest A.yaml doplní o manifest B.yaml, C.yaml pozor závisí v tomto případě na pořadí)
- reference mezi manifesty, je nutné dbát pozor na použítí suffixu / prefixu při pouívání referencí na jiné objekty, seznam kde lze použít objekt [referencí](https://github.com/kubernetes-sigs/kustomize/blob/a280cdf5eeb748f5a72c8d94164ffdd68d03c5ce/api/konfig/builtinpluginconsts/varreference.go)

## pipeline
- nemá smysl zbytečně vytvořet více containeru než je potřeba, jednodušší je určit dle názvu branche

# fuck-ups
- z 99% je problém na straně manifestům, tj nutné dodržet správné jméno a směrování služeb, deploymentl, containeru, configmap apod mezi sebou
- validace int env proměnnné docker vs kubernetes manifest => viz [configmap-nginx-config.yaml](kubernetes/base/configmap/configmap-nginx-config.yaml) (příklad selhání: KEY_NAME: ${INT_NUMBER}, KEY_NAME: "${INT_NUMBER}" => je konvertováno KEY_NAME: 100, má být KEY_NAME: "100")
- pokud je definovaný a buildovaný image pomoci docker compose, pozor environments jsou podstrčeny díky compose up z file a envu, tzn. při env proměnné při buildu nejsou
- pokud je použita proměnná v secretes v kustomize je nutné dbát na to aby bylo naplněna dřív než je proveden kustomize
- nevím jak to ale z nějakého důvodu, při buildování více image a a run stage, které jsou omezeny názvem branche, se předcházejí -> tím pádem se stane že daný image nemusí nutně existovat v danou chvíli

# to think about
- namespace k čemu slouží? k čemu slouží label? k čemu slouží prefix, suffix kustomize? co je výhodnější a proč?
    1. `devevelopment, dev11, ${suffix}-app-nginx + ${suffix}-app-web`
    2. `dev11, development, app-nginx + app-web`
- nasazování deployment jako A B prostředí? 
- je oprasvdu nutné používat omezení limitů k ochranně výkonu celého clusteru? [video](https://www.youtube.com/watch?v=KCFFZ_qfKXk)

## todo
- [x] kompose
- [x] version - rozděl version dle images
- [x] kube 11, od provozu, mozna kooperace s Mirou
- [-] version - nastav verzi podle posledního merge typu (major => breaking change, feature => z merge, fix => z merge) => není potřeba
- [x] docker conf, docker pull secret, kustomize secret generator, aby se pouzil googly pull secret,
- [x] first pipeline, simple docker image ok, docker compose faild caouse tagging inside docker compose?
- [ ] use setting->ci/cd->variables for sensitive data in env, .env split env to single files like now i am using it, but in deploy we can split to one?
- [ ] create docker-build.sh, kubernetes-build.sh, but split the build to seperate files, like -> init (minikube, kubectl, docker, docker-compose), pre-build (env, name of images), pre-docker, docker build, kubectl apply -> maybe from this we can create pipelines
- [ ] nastavit si kube11 vícenásobný konfig, jeden pro lokál, jeden pro kube11, naučit se switchování configu, tzn. nastavit oba configu abych je mohl switchovat
- [x] pipeline, kubectl
- [ ] jsem schoepn v dockerfile zjistit lokální architekturu a dle toho vybrat balík
