from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from jwt import PyJWTError, decode
from app.config import settings
from app.services.user_service import user_service

# 使用HTTPBearer来处理Bearer令牌
security = HTTPBearer(
    bearerFormat="JWT",
    description="Enter JWT token with Bearer prefix"
)

async def get_current_user(credentials = Depends(security)):
    """验证JWT令牌并获取当前用户"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = decode(credentials.credentials, settings.SECRET_KEY, algorithms=["HS256"])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except PyJWTError:
        raise credentials_exception
    
    user = await user_service.get_user(user_id)
    if user is None:
        raise credentials_exception
    
    return user