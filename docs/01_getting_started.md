// prepare dev env
```
cp compose.override.yaml.template compose.override.yaml
cp .env.dist .env
```

// start project
```
DOCKER_BUILDKIT=1 docker-compose up -d --build\n
```

// update /etc/hosts
```
127.0.0.1 boilerplatev2.localhost
```


