在一个Linux窗口安装并运行mongodb（db version v4\.4\.29），安装后使用

sudo mkdir \-p /data/db

sudo chown \-R $\(whoami\) /data/db

创建目录，然后运行mongod，在另一个窗口运行ps aux | grep mongod能够显示出守护进程即可成功运行。

通过pip install \-r requirements\.txt安装必要依赖后，在后端项目根目录下运行：python main\.py，后在浏览器访问[http://localhost:8000/docs\#/](http://localhost:8000/docs#/)，即可看到fastapi文档。

已支持的api如下：

__Chats:__

__/api/v1/chats/__	method:POST	__用于创建对话__

Request body: 

\{

  "user\_id": "string",

  "title": "New Chat",

  "model\_id": "string",

  "initial\_message": "string"

\}

__/api/v1/chats/\{chat\_id\}__	method:GET		__用于获取对话内容__

__/api/v1/chats/\{chat\_id\}__	method:DELETE		__删除此对话__

__/api/v1/chats/\{chat\_id\}/messages__	method:POST		__在此对话发送消息__

__/api/v1/chats/\{chat\_id\}/title__	method:PUT		__修改对话标题__

__History:__

__/api/v1/history/user/\{user\_id\}__		method:GET	__	获取此用户的对话历史__

__/api/v1/history/\{chat\_id\}/export__		method:GET		__将聊天记录导出为某格式__

