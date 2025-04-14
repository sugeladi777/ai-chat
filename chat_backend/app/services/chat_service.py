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
                "timestamp": datetime.now(timezone.utc)
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
                "timestamp": datetime.now(timezone.utc)
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
        chat = await self.get_chat(chat_id)
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