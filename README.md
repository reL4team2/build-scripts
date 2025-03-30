# Build Script

ARCH SUPPORTED:

1. riscv64
2. aarch64

### Run sel4-test

```shell
make ARCH=riscv64 sel4-test
```

### Run root-task-demo

```shell
make ARCH=riscv64 root-task-demo
```

Enjoy it 😆!


### ReL4 Dev Docker build

```shell
bash scripts/build_docker.sh
```

### ReL4 Dev Create container

```shell
bash scripts/start_docker.sh
```