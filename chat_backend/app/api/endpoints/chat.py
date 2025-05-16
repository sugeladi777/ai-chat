from fastapi import APIRouter, HTTPException, Form, Depends
from typing import Optional
from app.models.chat import ChatCreate
from app.services.chat_service import chat_service
from app.auth.dependencies import get_current_user

router = APIRouter()

@router.post("/", response_model=dict)
async def create_chat(
    chat_data: ChatCreate,
    current_user: dict = Depends(get_current_user)
):
    try:
        # 使用当前用户ID
        chat_id = await chat_service.create_chat(
            current_user["_id"],
            chat_data.title,
            chat_data.model_id or "default",
            chat_data.initial_message
        )
        return {"id": chat_id, "message": "Chat created successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{chat_id}", response_model=dict)
async def get_chat(chat_id: str, current_user: dict = Depends(get_current_user)):
    chat = await chat_service.get_chat(chat_id)
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # 验证权限
    if chat["user_id"] != current_user["_id"]:
        raise HTTPException(status_code=403, detail="You don't have permission to access this chat")
    
    return chat

@router.post("/{chat_id}/messages", response_model=dict)
async def add_message(
    chat_id: str,
    content: str = Form(...),
    current_user: dict = Depends(get_current_user)
):
    try:
        # 确认聊天属于当前用户
        chat = await chat_service.get_chat(chat_id)
        if not chat:
            raise HTTPException(status_code=404, detail="Chat not found")
        
        if chat["user_id"] != current_user["_id"]:
            raise HTTPException(status_code=403, detail="You don't have permission to access this chat")
        
        # 添加消息
        result = await chat_service.add_message(chat_id, content, files=None)
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{chat_id}")
async def delete_chat(chat_id: str, current_user: dict = Depends(get_current_user)):
    # 确认聊天属于当前用户
    chat = await chat_service.get_chat(chat_id)
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    if chat["user_id"] != current_user["_id"]:
        raise HTTPException(status_code=403, detail="You don't have permission to delete this chat")
    
    success = await chat_service.delete_chat(chat_id)
    if not success:
        raise HTTPException(status_code=404, detail="Chat not found")
    return {"message": "Chat deleted successfully"}

@router.put("/{chat_id}/title")
async def update_chat_title(
    chat_id: str,
    title: str = Form(None),  # 设为可选参数
    auto_generate: bool = Form(False),  # 新增参数，是否自动生成标题
    current_user: dict = Depends(get_current_user)
):
    # 确认聊天属于当前用户
    chat = await chat_service.get_chat(chat_id)  # 只需获取基本聊天信息
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    if chat["user_id"] != current_user["_id"]:
        raise HTTPException(status_code=403, detail="You don't have permission to update this chat")
    
    if auto_generate:
        # 使用AI自动生成标题
        try:
            new_title = await chat_service.generate_title(chat_id)
            return {"message": "Chat title updated successfully", "title": new_title}
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to generate title: {str(e)}")
    elif title:
        # 使用提供的标题
        success = await chat_service.update_chat_title(chat_id, title)
        if not success:
            raise HTTPException(status_code=404, detail="Chat not found")
        return {"message": "Chat title updated successfully", "title": title}
    else:
        raise HTTPException(status_code=400, detail="Either title or auto_generate must be provided")