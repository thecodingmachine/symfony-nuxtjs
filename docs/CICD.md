# Prod Deployment
@see [here](../gitlab-ci/gitlab-ci-tags-prod.yml)

This happen only when tag are pushed with format x.x.x

A production image is pushed to the tag then the gitlabci deploy it on the server

In gitlab, a variable named PROD_SSH_PRIVATE_KEY shall be added. It shall be encoded as base64 
The public key shall be added into the server

```
TMPDIR="$(mktemp -d)" && ssh-keygen -t ed25519 -q -N "" -C "gitlab@git.thecodingmachine.com" -f "${TMPDIR}/id_ed25519" && echo -e "Private as base64 :\n$(cat "${TMPDIR}/id_ed25519" | base64)\nPublic :\n$(cat "${TMPDIR}/id_ed25519.pub")" && rm -f "${TMPDIR}/id_ed25519"* && rmdir "${TMPDIR}"
```

As best practice, add the public key into gitlab variable so it is not lost

## Prepare a demo server

Theses steps are basis steps, it should be good enough for a demonstration environnement

```
cd /
sudo mkdir  tcm_deployment
sudo chown ubuntu:ubuntu tcm_deployment
cd tcm_deployment/
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub
```

Ajouter la clé dans Settings > repository > deploy key

Install docker dependencies
```
cd /tcm_deployment
git clone git@git.thecodingmachine.com:tcm-projects/analysec-app.git 
sudo apt-get update
sudo apt-get install     ca-certificates     curl     gnupg     lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo docker run hello-world
sudo apt  install docker-compose
sudo apt install make
cp .env.dist .env
cp compose.override.yaml.template  compose.override.yaml

sudo groupadd docker 
sudo usermod -aG docker $USER
```

To finish, Create a deploy token (NOT a key) named gitlab-deploy-token

After that, add the server IP into the gitlab-ci.yml

Then, on GIT tag, it should deploy
