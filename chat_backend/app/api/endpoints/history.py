from fastapi import APIRouter, HTTPException, Query
from typing import List
from app.services.chat_service import chat_service
from app.services.file_service import file_service

router = APIRouter()

@router.get("/user/{user_id}")
async def get_user_chats(user_id: str):
    try:
        chats = await chat_service.get_user_chats(user_id)
        return {"chats": chats}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{chat_id}/export")
async def export_chat(chat_id: str, format: str = Query("md", regex="^(md|txt)$")):
    """
    导出聊天记录为指定格式
    """
    try:
        # 获取聊天数据
        chat = await chat_service.get_chat(chat_id)
        if not chat:
            raise HTTPException(status_code=404, detail="Chat not found")
        
        # 导出为指定格式
        file_path = await file_service.export_chat(chat, format)
        
        # 返回文件信息
        return {
            "file_path": file_path,
            "filename": f"{chat['title']}.{format}".replace(" ", "_")
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))