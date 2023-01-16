#! /bin/bash -ex

gitlab_url="http://gitlab1.chinacscs.com/"
token="GR1348941FRE_FVWBKkdG_H8rbmN2"
description="XX项目"


if [$(yum list installed | grep docker | awk '{print $1}' | xargs) -eq ""]
then 
    echo "无旧版本"
else 
    echo "============================ 开始删除旧版本 =============================="
    yum -y remove $(yum list installed | grep docker | awk '{print $1}' | xargs)
    echo "============================ 删除旧版本完成 =============================="
fi

echo "============================ 开始设置yum下载docker的国内源 =============================="
yum-config-manager \
    --add-repo \
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
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
docker exec -u gitlab-runner gitlab-runner /bin/bash -c "source ~/.bashrc && nvm install 16.13.0 && nvm use 16.13.0"
echo "============================ nvm(nodejs)安装完成 =============================="