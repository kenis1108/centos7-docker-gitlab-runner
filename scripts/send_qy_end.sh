curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=6b0a1bd0-355b-456c-8654-9ddbc21dd2b6' \
   -H 'Content-Type: application/json' \
   -d '
   {
        "msgtype": "text",
        "text": {
            "content": "哥哥姐姐们，移动端前端部署完毕了呢(*^▽^*)"
        }
   }'