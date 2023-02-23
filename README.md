  
#  Gitlab-CI/CD (配置针对大B端前端)
  
  
***前提: 部署的机器可通外网以及访问内部的gitlab***
  
##  一、新建`.gitlab-ci.yml`
  
  
第一种: 在项目主分支(main/master)的根目录新建`.gitlab-ci.yml`并写入下面的内容并提交
  
![Untitled](assets/images/Untitled.png )
  
第二种: 在gitlab的流水线编辑器里写入下面的内容
  
![Untitled](assets/images/Untitled%201.png )
  
```yml
# 定义流水线所有的阶段(默认有三个阶段， build 、test 、deploy 三个阶段，即 构建 、测试 、部署)
stages:
  - build
  
# 作业执行前需要执行的命令
before_script:
  - echo "+++++++++++++++++++++ 开始构建 +++++++++++++++++++++++++++++++++"
  - source ~/.bashrc
  
# 定义一个作业(相当于函数的函数名)
build-job:
  # 定义作业所处流水线的阶段
  stage: build
  # 定义哪些分支运行，限制作业在什么上创建
  only:
    - main
  # 作业使用的Runner运行器的标签
  tags:
    - sit
  # 必须参数，运行器需要执行的脚本
  script:
    # 打印nvm,nodejs,yarn的版本号
    - nvm -v && node -v && yarn -v
    # 安装依赖
    - yarn
    - echo "=============================== 开始打包 ======================================== "
    # 执行package.json里的打包命令
    - yarn build
    # 打印项目根目录
    - ls
    - echo "=============================== 打包完成 ======================================== "
    # 压缩打好的包(需根据实际情况修改)
    - zip -r dist.zip dist
    # 将包上传到服务器(需根据实际情况修改)
    - scp dist.zip appadmin@172.17.8.195:/data/web/sxzq
    # 替换服务器上的包(需根据实际情况修改)
    - ssh appadmin@172.17.8.195 "cd /data/web/sxzq;mv platform platform$(date +%y%m%d%H%M);unzip dist.zip && mv dist platform;"
    - echo “=============================== 发布完成 ======================================== ”
  # 归档文件列表，指定成功后应附加到job的文件和目录的列表(保留打好的包,可在job页面下载)
  artifacts:
    # 打包好的.zip文件名
    name: "dist"
    # 打包的目录
    paths: 
      - dist/
```  
  
##  二、配置runner(远程容器)和nodejs(nvm)
  
  
在本地拉取代码`git clone http://gitlab.chihttnacsci.com/test-gitlab-cicd/centos7-docker-gitlab-runner.git` 
  
![Untitled](assets/images/Untitled%202.png )
  
获取gitlab_url和token
  
![Untitled](assets/images/Untitled%203.png )
  
修改`scripts/centos7_install_docker.sh`里的变量
  
![Untitled](assets/images/Untitled%204.png )
  
```sh
#! /bin/bash -ex
  
# 注册runner的地址
gitlab_url="http://gitlab1.chinacscs.com/"
# 注册runner的token
token="GR1348941FRE_FVWBKkdG_H8rbmN2"
# 对这个runner的描述
description="XX项目"
# 想要安装nodejs的版本号
nodejs_version="16.13.0"
# 您的名字
your_name="kkb"
# 通过ssh连接linux服务器的用户名
server_username="appadmin"
# linux服务器ip
server_ip="172.18.0.3"
  
# 检查服务器是否已安装docker
docker version
if [ $? -eq 0 ]
then 
    echo "============================ 开始删除旧版本 =============================="
    yum -y remove $(yum list installed | grep docker | awk '{print $1}' | xargs)
    echo "============================ 删除旧版本完成 =============================="
else 
    echo "无旧版本"
fi
  
echo "============================ 开始设置yum下载docker的国内源 =============================="
# 检查服务器是否已安装yum-utils
yum-config-manager --version
if [ $? -eq 0 ]
then
    yum-config-manager \
        --add-repo \
        http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
else
    # yum-config-manager command not found
    yum -y install yum-utils
    yum-config-manager \
        --add-repo \
        http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
fi
  
echo "============================ 已设置国内源(aliyun) =============================="
  
echo "============================ 开始安装docker =============================="
yum -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
echo "============================ docker已安装 =============================="
  
echo "============================ 启动docker服务 =============================="
systemctl start docker
echo "============================ docker服务已启动 =============================="
  
echo "============================ 开始拉取gitlab/gitlab-runner镜像 =============================="
docker pull gitlab/gitlab-runner
echo "============================ 拉取镜像完成 =============================="
  
echo "============================ 运行容器 =============================="
docker run -itd --restart=always --name gitlab-runner \
-v /root/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock  gitlab/gitlab-runner
echo "============================ 容器已运行 =============================="
  
echo "============================ 开始注册runner =============================="
docker exec gitlab-runner /bin/bash -c "gitlab-runner register --non-interactive --url ${gitlab_url} --registration-token ${token} --executor 'shell' --description ${description}"
echo "============================ 注册runner完成 =============================="
  
echo "============================ 给用户gitlab-runner安装nvm(nodejs) =============================="
docker exec -u gitlab-runner gitlab-runner /bin/bash -c "git clone https://gitee.com/mirrors/nvm ~/.nvm"
docker cp ../assets/.bashrc gitlab-runner:/home/gitlab-runner/.bashrc
docker exec -u gitlab-runner gitlab-runner /bin/bash -c "source ~/.bashrc && nvm install ${nodejs_version} && nvm use ${nodejs_version} && npm i -g yarn"
echo "============================ nvm(nodejs)安装完成 =============================="
  
echo "============================ gitlab-runner用户生成ssh密钥以便连接部署的服务器 =============================="
docker exec -u gitlab-runner gitlab-runner /bin/bash -c "ssh-keygen -t rsa -C '${your_name}' -f '/home/gitlab-runner/.ssh/${your_name}_rsa'"
# docker exec -u gitlab-runner gitlab-runner /bin/bash -c "ssh-copy-id -i /home/gitlab-runner/.ssh/${your_name}_rsa.pub ${server_username}@${server_ip}"
docker exec -u gitlab-runner gitlab-runner /bin/bash -c "cat /home/gitlab-runner/.ssh/${your_name}_rsa.pub" > ../authorized_keys
scp ../authorized_keys ${server_username}@${server_ip}:/home/${server_username}/.ssh/
echo "============================ gitlab-runner用户配置免密登录部署服务器完成 =============================="
```  
  
到`centos7-docker-gitlab-runner` 文件夹的上一级将该目录上传到服务器上
  
```bash
# scp 要上传的目录 用户名@ip:目标地址
scp -r centos7-docker-gitlab-runner appadmin@172.17.8.195:/home/appadmin
```
  
![Untitled](assets/images/Untitled%205.png )
  
输入密码后成功的截图
  
![Untitled](assets/images/Untitled%206.png )
  
登录服务器后切换到root用户
  
```bash
# ssh命令: ssh 用户名@ip
# 切换到root命令: sudo -i
```
  
![Untitled](assets/images/Untitled%207.png )
  
cd到`centos7-docker-gitlab-runner/scripts`执行安装脚本
  
```bash
cd /home/appadmin/centos7-docker-gitlab-runner/scripts && bash ./centos7_install_docker.sh
```
  
---
  
##  三、新增runner
  
  
(登录服务器进行下面的操作)
  
1. 同一台服务器的同一个容器里新增runner的情况
  
```bash
# 变量替换成实际值
docker exec gitlab-runner /bin/bash -c "gitlab-runner register --non-interactive --url ${gitlab_url} --registration-token ${token} --executor 'shell' --description ${description}"
# 开发环境(nodejs和ssh)就不需要重新配置
```
  
1. 同一台服务器不同容器的情况
  
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
  
1. 不同服务器重新跑脚本
2. 根据公司提供的服务器性能,个人建议不要在同一台服务器配太多个runner,因为当同时有多个runner在执行作业时服务器内存不够会自动把后端java服务干掉
  
---
  