  
  
#  Gitlab-CI/CD (针对大B端前端-自行改ip和路径)
  
  
##  准备
  
  
参考: 
  
[Run GitLab Runner in a container | GitLab](https://docs.gitlab.com/runner/install/docker.html )
  
公司虚拟机发行版: CentOS Linux release 7.9.2009
  
![Untitled](assets/images/Untitled.png )
  
![Untitled](assets/images/Untitled%201.png )
  
本地测试机: centos:7(docker)
  
```bash
docker run -itd -v C:\Users\kk\Documents\zzsz\centos7-docker-gitlab-runner:/root/centos7-docker-gitlab-runner --privileged --name test-centos-gitlab-cicd centos:7 init
# --privileged 特权模式
# init 可运行systemctl等命令
```
  
![Untitled](assets/images/Untitled%202.png )
  
可ping通内网gitlab
  
![Untitled](assets/images/Untitled%203.png )
  
##  一、服务器创建脚本（备份-解压）
  
  
```sh
time=`date +%y%m%d%H%M` # 获取当前时间并格式化
newdir=`mv platform platform${time}` # 备份
$newdir # 运行命令
unzip dist.zip # 解压
mv dist platform # 重命名
```  
  
##  二、新建.gitlab-ci.yml
  
  
```yml
stages:
  - build
  
before_script:
  - echo "+++++++++++++++++++++ 开始构建 +++++++++++++++++++++++++++++++++"
  - source ~/.bashrc
  
build-job:
  stage: build
  only:
    - main
  tags:
    - sit
  script:
    - nvm -v
    - node -v
    - yarn -v
    - yarn
    - echo "=============================== 开始打包 ======================================== "
    - yarn build
    - ls
    - echo "=============================== 打包完成 ======================================== "
    - zip -r dist.zip dist # 压缩
    - scp dist.zip appadmin@172.17.8.195:/data/web/sxzq # 上传
    - ssh appadmin@172.17.8.195 "cd /data/web/sxzq;sh ./setup.sh" # 执行服务器上的部署脚本
    - echo “=============================== 发布完成 ======================================== ”
  artifacts: # 保留打好的包,可在job页面下载
    name: "dist"
    paths: 
      - dist/
```  
  
##  三、配置runner(远程容器)和nodejs(nvm)
  
  
公司的服务器一般都是CentOS7
  
```sh
#! /bin/bash -ex
# scripts/centos7_install_docker.sh
  
gitlab_url="http://gitlab1.chinacscs.com/"
token="GR1348941FRE_FVWBKkdG_H8rbmN2"
description="XX项目"
nodejs_version="16.13.0"
  
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
```  
  
##  四、给gitlab-runner用户配置ssh密钥
  
  
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
6. 复制setup.sh到服务器上项目的部署目录
7. 复制.gitlab-ci.yml到项目中编辑并提交
  
##  五、新增runner
  
  
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
  