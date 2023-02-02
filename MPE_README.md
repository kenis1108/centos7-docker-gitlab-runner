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

## 一、新建.gitlab-ci.yml

@import "./.gitlab-ci.yml"

## 二、配置runner(远程容器)和nodejs(nvm)

公司的服务器一般都是CentOS7

@import "./scripts/centos7_install_docker.sh"

## 三、给gitlab-runner用户配置ssh密钥

```bash
docker exec -it -u gitlab-runner gitlab-runner /bin/bash
# ssh密钥
ssh-keygen -t rsa -C "kkbdsg"
ssh-copy-id -i ~/.ssh/id_rsa.pub sxzq@172.17.8.195
```

实战:

1. 确保服务器可以连外网
2. `git clone git@gitlab.chinacsci.com:test-gitlab-cicd/centos7-docker-gitlab-runner.git`
3. 修改centos7_install_docker.sh里的变量
4. 用root执行centos7_install_docker.sh
5. 配置密钥
6. 复制.gitlab-ci.yml到项目中编辑并提交

## 四、新增runner

1. 同一台服务器的同一个容器里新增runner的情况

```bash
# 变量替换成实际值
docker exec gitlab-runner /bin/bash -c "gitlab-runner register --non-interactive --url ${gitlab_url} --registration-token ${token} --executor 'shell' --description ${description}"
# 开发环境(nodejs和ssh)就不需要重新配置
```

2. 同一台服务器不同容器的情况

```bash
# 新开一个容器--name需要换成跟已经存在的容器名不一样的
docker run -itd --restart=always --name gitlab-runner1 \
-v /root/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock  gitlab/gitlab-runner
# 后续注册和配置环境
docker exec gitlab-runner1 /bin/bash -c "gitlab-runner register --non-interactive --url ${gitlab_url} --registration-token ${token} --executor 'shell' --description ${description}"
docker exec -u gitlab-runner gitlab-runner1 /bin/bash -c "git clone https://gitee.com/mirrors/nvm ~/.nvm"
docker cp ../assets/.bashrc gitlab-runner1:/home/gitlab-runner/.bashrc
docker exec -u gitlab-runner gitlab-runner1 /bin/bash -c "source ~/.bashrc && nvm install ${nodejs_version} && nvm use ${nodejs_version} && npm i -g yarn"
```

3. 不同服务器重新跑脚本
4. 根据公司提供的服务器性能,个人建议不要在同一台服务器配太多个runner,因为当同时有多个runner在执行作业时服务器内存不够会自动把后端java服务干掉,一开始以为是后端部署或代码有问题其实是runner的锅导致内存不够用