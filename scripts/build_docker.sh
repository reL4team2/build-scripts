docker build --network=host --build-arg https_proxy=http://127.0.0.1:7890 --build-arg http_proxy=http://127.0.0.1:7890 -t croakexciting/rel4_dev:0.0.6 -f ./docker/rel4.dockerfile ./docker
