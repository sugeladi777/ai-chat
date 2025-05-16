from fastapi import APIRouter
from app.api.endpoints import chat, history, files,auth


api_router = APIRouter()

api_router.include_router(chat.router, prefix="/chats", tags=["chats"])
api_router.include_router(history.router, prefix="/history", tags=["history"])
api_router.include_router(files.router, prefix="/files", tags=["files"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])