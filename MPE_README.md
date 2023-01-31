---
markdown:
  path: README.md
  ignore_from_front_matter: true
  absolute_image_path: false
export_on_save:
  markdown: true
---

# Gitlab-CI/CD (针对大B端前端-自行改ip和路径)

## 准备

参考: 

[Run GitLab Runner in a container | GitLab](https://docs.gitlab.com/runner/install/docker.html)

公司虚拟机发行版: CentOS Linux release 7.9.2009

![Untitled](assets/images/Untitled.png)

![Untitled](assets/images/Untitled%201.png)

本地测试机: centos:7(docker)

```bash
docker run -itd -v C:\Users\kk\Documents\zzsz\centos7-docker-gitlab-runner:/root/centos7-docker-gitlab-runner --privileged --name test-centos-gitlab-cicd centos:7 init
# --privileged 特权模式
# init 可运行systemctl等命令
```

![Untitled](assets/images/Untitled%202.png)

可ping通内网gitlab

![Untitled](assets/images/Untitled%203.png)

## 一、服务器创建脚本（备份-解压）

@import "./scripts/setup.sh"

## 二、新建.gitlab-ci.yml

@import "./.gitlab-ci.yml"

## 三、配置runner(远程容器)和nodejs(nvm)

公司的服务器一般都是CentOS7

@import "./scripts/centos7_install_docker.sh"

## 四、给gitlab-runner用户配置ssh密钥

```bash
docker exec -it -u gitlab-runner gitlab-runner /bin/bash
# ssh密钥
ssh-keygen -t rsa -C "kkbdsg"
ssh-copy-id -i ~/.ssh/id_rsa.pub sxzq@172.17.8.195
```

实战:

1. 确保服务器可以连外网
2. `git clone git@gitlab.chinacsci.com:test-gitlab-cicd/centos7-docker-gitlab-runner.git`
3. 修改centos7_install_docker.sh
4. 用root执行centos7_install_docker.sh
5. 配置密钥
6. 复制setup.sh到服务器上项目的部署目录
7. 复制.gitlab-ci.yml到项目中编辑并提交
