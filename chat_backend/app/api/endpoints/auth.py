from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.models.user import UserCreate, UserLogin, UserUpdate
from app.services.user_service import user_service
from app.auth.dependencies import get_current_user
from app.config import settings

router = APIRouter()

@router.post("/register")
async def register(user_data: UserCreate):
    """注册新用户"""
    try:
        result = await user_service.register(user_data)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/login")
async def login(user_data: UserLogin):
    """用户登录"""
    try:
        result = await user_service.login(user_data)
        return result
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/me", summary="获取当前用户信息")
async def get_me(current_user = Depends(get_current_user)):
    """获取当前登录用户信息"""
    return current_user

# 新增：更新用户昵称
@router.patch("/nickname", summary="更新用户昵称")
async def update_nickname(
    update_data: UserUpdate,
    current_user: dict = Depends(get_current_user)
):
    """更新当前用户的昵称"""
    try:
        # 使用当前用户ID更新昵称
        updated_user = await user_service.update_nickname(current_user["_id"], update_data)
        return updated_user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 新增：上传用户头像
@router.post("/avatar", summary="上传用户头像")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """上传用户头像"""
    try:
        # 验证文件类型
        if file.content_type not in settings.ALLOWED_AVATAR_TYPES:
            raise HTTPException(
                status_code=400, 
                detail=f"Only {', '.join(settings.ALLOWED_AVATAR_TYPES)} are allowed"
            )
        
        # 上传头像
        result = await user_service.upload_avatar(current_user["_id"], file)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 新增：获取当前用户头像
@router.get("/avatar", summary="获取当前用户头像URL")
async def get_avatar(current_user: dict = Depends(get_current_user)):
    """获取当前用户的头像URL"""
    return {"avatar_url": current_user.get("avatar_url")}