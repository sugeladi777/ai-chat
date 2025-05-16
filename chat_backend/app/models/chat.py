from typing import List, Optional, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field
from app.models.common import PyObjectId

class Message(BaseModel):
    role: str
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    hidden:bool=False
    
class Chat(BaseModel):
    id: Optional[PyObjectId] = Field(default=None, alias="_id")
    user_id: str
    title: str
    model_id: str
    messages: List[Message] = []
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        validate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {
            PyObjectId: lambda oid: str(oid),
        }

class ChatCreate(BaseModel):
    title: str = "New Chat"
    model_id: Optional[str] = None
    initial_message: Optional[str] = None
    # 用户ID现在从JWT获取，而不是从请求中提供

class ChatResponse(BaseModel):
    id: str
    title: str
    model_id: str
    created_at: datetime
    updated_at: datetime
    last_message: Optional[str] = None
    
class MessageCreate(BaseModel):
    content: str
    files: Optional[List[str]] = None
    
class MessageResponse(BaseModel):
    role: str
    content: str
    timestamp: datetime