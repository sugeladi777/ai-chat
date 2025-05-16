from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi import Depends, HTTPException, status
from jwt import PyJWTError, decode
from app.config import settings
from app.services.user_service import user_service

# 创建HTTP Bearer安全方案
security = HTTPBearer(
    scheme_name="JWT Authentication",
    description="Enter your JWT token",
    auto_error=True
)

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """验证JWT令牌并获取当前用户"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # 解码JWT令牌
        payload = decode(credentials.credentials, settings.SECRET_KEY, algorithms=["HS256"])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except PyJWTError:
        raise credentials_exception
    
    # 获取用户信息
    user = await user_service.get_user(user_id)
    if user is None:
        raise credentials_exception
    
    return user