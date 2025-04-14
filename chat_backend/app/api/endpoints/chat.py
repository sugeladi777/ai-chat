from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form, Query
from typing import List, Optional
from app.models.chat import ChatCreate, ChatResponse, MessageCreate, MessageResponse
from app.services.chat_service import chat_service
from app.services.file_service import file_service

router = APIRouter()

@router.post("/", response_model=dict)
async def create_chat(chat_data: ChatCreate):
    try:
        chat_id = await chat_service.create_chat(
            chat_data.user_id,
            chat_data.title,
            chat_data.model_id or "default",
            chat_data.initial_message
        )
        return {"id": chat_id, "message": "Chat created successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{chat_id}", response_model=dict)
async def get_chat(chat_id: str):
    chat = await chat_service.get_chat(chat_id)
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    return chat

@router.post("/{chat_id}/messages", response_model=dict)
async def add_message(
    chat_id: str,
    content: str = Form(...),
    files: List[UploadFile] = File(None)
):
    try:
        # 保存上传的文件
        file_paths = []
        if files:
            for file in files:
                if file.filename:  # 确保有文件上传
                    file_path = await file_service.save_file(file)
                    file_paths.append(file_path)
        
        # 添加消息并获取回复
        result = await chat_service.add_message(chat_id, content, file_paths)
        
        # 消息发送后可以删除临时文件
        for file_path in file_paths:
            file_service.delete_file(file_path)
            
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{chat_id}")
async def delete_chat(chat_id: str):
    success = await chat_service.delete_chat(chat_id)
    if not success:
        raise HTTPException(status_code=404, detail="Chat not found")
    return {"message": "Chat deleted successfully"}

@router.put("/{chat_id}/title")
async def update_chat_title(chat_id: str, title: str = Form(...)):
    success = await chat_service.update_chat_title(chat_id, title)
    if not success:
        raise HTTPException(status_code=404, detail="Chat not found")
    return {"message": "Chat title updated successfully"}