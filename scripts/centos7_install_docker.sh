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

echo "============================ 给用户gitlab-runner安装jdk-17 =============================="
docker exec -u gitlab-runner gitlab-runner /bin/bash -c "cd && wget https://mirrors.huaweicloud.com/openjdk/17/openjdk-17_linux-x64_bin.tar.gz"
docker exec -u gitlab-runner gitlab-runner /bin/bash -c "cd && tar -zxvf openjdk-17_linux-x64_bin.tar.gz"
echo "============================ 给用户gitlab-runner安装jdk-17 =============================="

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