from fastapi import APIRouter
from app.api.endpoints import chat, history, files

api_router = APIRouter()

api_router.include_router(chat.router, prefix="/chats", tags=["chats"])
api_router.include_router(history.router, prefix="/history", tags=["history"])
api_router.include_router(files.router, prefix="/files", tags=["files"])