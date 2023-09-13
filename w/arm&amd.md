<center>docker buildx构建镜像镜像使用示例及规范</center>

## 1.1 官方镜像制作：docker manifest

- 准备kube-apiserver:v1.21.2 amd64/arm64镜像

```shell
$ docker pull k8s.gcr.io/kube-apiserver-amd64:v1.21.2
$ docker pull k8s.gcr.io/kube-apiserver-arm64:v1.21.2
```



- 重新打tag并推送到自己的仓库

```shell
$ docker tag k8s.gcr.io/kube-apiserver-amd64:v1.21.2 10.50.208.30:30012/multi-arch-test/kube-apiserver-amd64:v1.21.2
$ docker tag k8s.gcr.io/kube-apiserver-arm64:v1.21.2 10.50.208.30:30012/multi-arch-test/kube-apiserver-arm64:v1.21.2
$ docker push 10.50.208.30:30012/multi-arch-test/kube-apiserver-amd64:v1.21.2
$ docker push 10.50.208.30:30012/multi-arch-test/kube-apiserver-arm64:v1.21.2
```



- 创建/推送 `manifest` 

```shell
$ docker manifest create --insecure 10.50.208.30:30012/multi-arch-test/kube-apiserver:v1.21.2 10.50.208.30:30012/multi-arch-test/kube-apiserver-amd64:v1.21.2 10.50.208.30:30012/multi-arch-test/kube-apiserver-arm64:v1.21.2
$ docker manifest  push  --insecure 10.50.208.30:30012/multi-arch-test/kube-apiserver:v1.21.2
```



- 拉取验证

```shell
x86_64机器拉取
$ docker pull 10.50.208.30:30012/multi-arch-test/kube-apiserver:v1.21.2
$ docker images |grep v1.21.2
10.50.208.30:30012/multi-arch-test/kube-apiserver-arm64                                               v1.21.2                                                                       2811c599675e   2 years ago     117MB
k8s.gcr.io/kube-apiserver-arm64                                                                       v1.21.2                                                                       2811c599675e   2 years ago     117MB
10.50.208.30:30012/multi-arch-test/kube-apiserver-amd64                                               v1.21.2                                                                       106ff58d4308   2 years ago     126MB
10.50.208.30:30012/multi-arch-test/kube-apiserver                                                     v1.21.2                                                                       106ff58d4308   2 years ago     126MB
k8s.gcr.io/kube-apiserver-amd64                                                                       v1.21.2                                                                       106ff58d4308   2 years ago     126MB

arm64机器拉取
$ docker pull 10.50.208.30:30012/multi-arch-test/kube-apiserver:v1.21.2
$ docker images |grep v1.21.2
10.50.208.30:30012/multi-arch-test/kube-apiserver   v1.21.2   2811c599675e   2 years ago   117MB

```

## 1.2 自研组件镜像制作：docker buildx

**前置条件**：docker已安装

- 下载对应的[buildx](https://github.com/docker/buildx/releases/)二进制文件，放到目录`$HOME/.docker/cli-plugins`中，执行`docker buildx version`查看效果
- 设置： http: server gave HTTP response to HTTPS client

```shell
$ vi /etc/docker/buildkitd.toml
[registry."10.50.208.30:30012"]
  http = true
  insecure = true
```

- 从默认的构建器切换到多平台构建器`docker buildx create  --use --config /etc/docker/buildkitd.toml`

**可选参数**：`--driver-opt env.http_proxy=http://yourproxyIP:port--driver-opt env.https_proxy=http://yourproxyIP:port --driver-opt '"env.no_proxy=localhost,127.0.0.1"'`

- 测试代码

```shell
$ vi main.go
package main

import (
   "fmt"
   "runtime"
)

func main() {
   fmt.Printf("the current platform architecture is %s.\n", runtime.GOARCH)
}

$ vi Dockerfile
FROM golang:latest
WORKDIR /app
COPY main.go /app
RUN go build -o multi-arch-test /app/main.go
CMD ["./multi-arch-test"]
```

- 编译多架构镜像并推送

```shell
$ docker buildx build -t 10.50.208.30:30012/multi-arch-test/multi-arch-test:v1.0.0 --platform=linux/arm64,linux/amd64 . --push
```



- 验证

```shell
amd64
$ docker run --rm 10.50.208.30:30012/multi-arch-test/multi-arch-test:v1.0.0
Status: Downloaded newer image for 10.50.208.30:30012/multi-arch-test/multi-arch-test:v1.0.0
the current platform architecture is amd64

arm64
$ docker run --rm 10.50.208.30:30012/multi-arch-test/multi-arch-test:v1.0.0
Status: Downloaded newer image for 10.50.208.30:30012/multi-arch-test/multi-arch-test:v1.0.0
the current platform architecture is arm64.
```
