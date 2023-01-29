time=`date +%y%m%d%H%M` # 获取当前时间并格式化
newdir=`mv platform platform${time}` # 备份
$newdir # 运行命令
unzip dist.zip # 解压
mv dist platform # 重命名