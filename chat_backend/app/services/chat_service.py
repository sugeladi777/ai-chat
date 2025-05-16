from typing import List, Dict, Optional, Any
from datetime import datetime,timezone
from bson import ObjectId
from app.database import db
from app.models.chat import Chat, Message
from app.services.ai_service import ai_service

class ChatService:
    async def create_chat(self, user_id: str, title: str, model_id: str, initial_message: Optional[str] = None) -> str:
        """
        创建新的对话
        """
        chat = {
            "user_id": user_id,
            "title": title,
            "model_id": model_id,
            "messages": [],
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        }
        
        if initial_message:
            # 添加用户的初始消息
            chat["messages"].append({
                "role": "user",
                "content": initial_message,
                "timestamp": datetime.now(timezone.utc),
                "hidden":True
            })
            
            # 获取AI回复
            ai_response = await ai_service.get_response(
                [{"role": "user", "content": initial_message}],
                model_id
            )
            
            # 添加AI回复
            chat["messages"].append({
                "role": "assistant",
                "content": ai_response,
                "timestamp": datetime.now(timezone.utc),
                "hidden":True
            })
        
        result = await db.db.chats.insert_one(chat)
        return str(result.inserted_id)
    
    async def get_chat(self, chat_id: str) -> Optional[Dict[str, Any]]:
        """
        获取聊天详情
        """
        chat = await db.db.chats.find_one({"_id": ObjectId(chat_id)})
        if chat:
            chat["_id"] = str(chat["_id"])
            chat["messages"]=[msg for msg in chat["messages"] if not msg.get("hidden",False)]
        return chat
    
    async def get_user_chats(self, user_id: str) -> List[Dict[str, Any]]:
        """
        获取用户的所有聊天
        """
        cursor = db.db.chats.find({"user_id": user_id}).sort("updated_at", -1)
        chats = []
        
        async for chat in cursor:
            chat["_id"] = str(chat["_id"])
            # 只包含最后一条消息作为预览
            if chat["messages"]:
                chat["last_message"] = chat["messages"][-1]["content"]
            else:
                chat["last_message"] = ""
            del chat["messages"]  # 不返回完整的消息历史
            chats.append(chat)
            
        return chats
    
    async def add_message(self, chat_id: str, content: str, files: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        添加新消息并获取AI回复
        """
        # 获取现有对话
        chat = await self.get_chat_with_hidden(chat_id)  # 使用get_chat_with_hidden而不是get_chat
        if not chat:
            raise ValueError("Chat not found")
        
        # 处理文件内容
        file_contents = ""
        if files:
            for file_path in files:
                file_content = await ai_service.process_file(file_path)
                file_contents += f"\n\n{file_content}"
            
            # 如果有文件内容，添加到消息中
            if file_contents:
                content += file_contents
        
        # 添加用户消息
        user_message = {
            "role": "user",
            "content": content,
            "timestamp": datetime.utcnow()
        }
        
        # 准备AI请求的消息历史
        message_history = [
            {"role": m["role"], "content": m["content"]}
            for m in chat["messages"]
        ]
        message_history.append({"role": "user", "content": content})
        
        # 获取AI回复
        ai_response = await ai_service.get_response(
            message_history,
            chat["model_id"]
        )
        
        # 添加AI回复
        ai_message = {
            "role": "assistant",
            "content": ai_response,
            "timestamp": datetime.now(timezone.utc)
        }
        
        # 更新数据库
        await db.db.chats.update_one(
            {"_id": ObjectId(chat_id)},
            {
                "$push": {
                    "messages": {
                        "$each": [user_message, ai_message]
                    }
                },
                "$set": {
                    "updated_at": datetime.now(timezone.utc)
                }
            }
        )
        
        return {
            "user_message": user_message,
            "ai_message": ai_message
        }
    
    async def delete_chat(self, chat_id: str) -> bool:
        """
        删除聊天
        """
        result = await db.db.chats.delete_one({"_id": ObjectId(chat_id)})
        return result.deleted_count > 0
    
    async def generate_title(self, chat_id: str) -> str:
        """
        使用AI生成聊天标题，但不将提示和回答添加到message中
        """
        # 获取聊天记录
        chat = await self.get_chat_with_hidden(chat_id)
        if not chat:
            raise ValueError("Chat not found")
        
        # 过滤掉隐藏消息，只使用可见消息生成标题
        visible_messages = [msg for msg in chat["messages"] if not msg.get("hidden", False)]
        
        # 如果没有可见消息，使用默认标题
        if not visible_messages:
            return "New Chat"
        
        # 准备提示词
        prompt = "请主要参考用户的意图，为以下对话生成一个简短的标题（不超过20个字），只回复标题内容，不要包含其他解释：\n\n"
        
        # 添加对话内容（最多取前5条消息避免过长）
        for i, msg in enumerate(visible_messages[:5]):
            role = "用户" if msg["role"] == "user" else "助手"
            prompt += f"{role}: {msg['content'][:100]}{'...' if len(msg['content']) > 100 else ''}\n"
        
        # 调用AI生成标题，但不添加到消息历史中
        model_id = chat["model_id"]
        
        # 直接调用AI服务，获取生成的标题
        title_response = await ai_service.get_response(
            [{"role": "user", "content": prompt}],
            model_id
        )
        
        # 清理回复，去除可能的引号和多余空格
        title = title_response.strip().strip('"\'').strip()
        
        # 如果标题为空或过长，使用默认值
        if not title or len(title) > 50:
            title = "New Chat"
        
        # 仅更新聊天标题，不添加任何消息
        await db.db.chats.update_one(
            {"_id": ObjectId(chat_id)},
            {
                "$set": {
                    "title": title, 
                    "updated_at": datetime.now(timezone.utc)
                }
            }
        )
    
        return title

    async def get_chat_with_hidden(self, chat_id: str) -> Optional[Dict[str, Any]]:
        """
        获取聊天详情，包括隐藏消息
        """
        chat = await db.db.chats.find_one({"_id": ObjectId(chat_id)})
        if chat:
            chat["_id"] = str(chat["_id"])
        return chat



    async def update_chat_title(self, chat_id: str, title: str) -> bool:
        """
        更新聊天标题
        """
        result = await db.db.chats.update_one(
            {"_id": ObjectId(chat_id)},
            {"$set": {"title": title, "updated_at": datetime.utcnow()}}
        )
        return result.modified_count > 0

chat_service = ChatService()