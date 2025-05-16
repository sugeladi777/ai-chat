import os
import uuid
import shutil
from typing import Optional, Dict, Any
from datetime import datetime, timedelta, timezone
import jwt
from passlib.context import CryptContext
from bson import ObjectId
from fastapi import UploadFile, HTTPException
from app.database import db
from app.config import settings
from app.models.user import UserCreate, UserLogin, UserUpdate

class UserService:
    def __init__(self):
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        self.secret_key = settings.SECRET_KEY
        self.token_expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
        
        # 确保头像上传目录存在
        os.makedirs(settings.AVATAR_DIR, exist_ok=True)
        
    def _hash_password(self, password: str) -> str:
        """密码哈希"""
        return self.pwd_context.hash(password)
    
    def _verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """验证密码"""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def _create_access_token(self, data: dict) -> str:
        """创建JWT令牌"""
        to_encode = data.copy()
        expire = datetime.now(timezone.utc) + timedelta(minutes=self.token_expire_minutes)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm="HS256")
        return encoded_jwt
    
    async def register(self, user_data: UserCreate) -> Dict[str, Any]:
        """注册新用户"""
        # 检查邮箱是否已存在
        existing_user = await db.db.users.find_one({"email": user_data.email})
        if existing_user:
            raise ValueError("Email already registered")
        
        # 检查用户名是否已存在
        existing_username = await db.db.users.find_one({"username": user_data.username})
        if existing_username:
            raise ValueError("Username already taken")
        
        # 创建新用户
        user = {
            "username": user_data.username,
            "email": user_data.email,
            "password_hash": self._hash_password(user_data.password),
            "nickname": user_data.nickname,  # 新增：支持注册时设置昵称
            "avatar_url": None,  # 初始化为空
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        }
        
        result = await db.db.users.insert_one(user)
        user_id = str(result.inserted_id)
        
        # 创建并返回访问令牌
        access_token = self._create_access_token({"sub": user_id})
        
        return {
            "id": user_id,
            "username": user_data.username,
            "email": user_data.email,
            "nickname": user_data.nickname,
            "avatar_url": None,
            "access_token": access_token,
            "token_type": "bearer"
        }
    
    async def login(self, user_data: UserLogin) -> Dict[str, Any]:
        """用户登录 - 支持用户名或邮箱"""
        # 确定使用哪个字段进行查询
        # if user_data.email:
        #     # 优先使用邮箱查询
        #     query = {"email": user_data.email}
        # elif user_data.username:
            # 如果没有提供邮箱，使用用户名查询
        query = {"username": user_data.username}
        #else:
        if not user_data.username:
            # 两者都没有提供
            raise ValueError("Either username or email must be provided")
        
        # 查找用户
        user = await db.db.users.find_one(query)
        if not user:
            raise ValueError("Invalid credentials")
        
        # 验证密码
        if not self._verify_password(user_data.password, user["password_hash"]):
            raise ValueError("Invalid credentials")
        
        # 创建访问令牌
        user_id = str(user["_id"])
        access_token = self._create_access_token({"sub": user_id})
        
        return {
            "id": user_id,
            "username": user["username"],
            "email": user["email"],
            "nickname": user.get("nickname"),
            "avatar_url": user.get("avatar_url"),
            "access_token": access_token,
            "token_type": "bearer"
        }
    
    async def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """获取用户信息"""
        user = await db.db.users.find_one({"_id": ObjectId(user_id)})
        if user:
            # 转换ID为字符串
            user["_id"] = str(user["_id"])
            
            # 不返回密码哈希
            user.pop("password_hash", None)
            
            # 确保必须的字段存在，即使在数据库中不存在
            if "nickname" not in user:
                user["nickname"] = None
                
            if "avatar_url" not in user:
                user["avatar_url"] = None
        return user
    
    async def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """通过邮箱获取用户"""
        user = await db.db.users.find_one({"email": email})
        if user:
            user["_id"] = str(user["_id"])
            # 不返回密码哈希
            user.pop("password_hash", None)
        return user
    
    # 新增：更新用户昵称
    async def update_nickname(self, user_id: str, update_data: UserUpdate) -> Dict[str, Any]:
        """更新用户昵称"""
        if not update_data.nickname:
            raise ValueError("Nickname cannot be empty")
            
        # 更新用户昵称
        now = datetime.now(timezone.utc)
        result = await db.db.users.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": {
                "nickname": update_data.nickname,
                "updated_at": now
            }}
        )
        
        if result.matched_count == 0:
            raise ValueError("User not found")
            
        # 获取更新后的用户信息
        return await self.get_user(user_id)
    
    # 新增：上传用户头像
    async def upload_avatar(self, user_id: str, file: UploadFile) -> Dict[str, Any]:
        """上传用户头像"""
        # 验证文件类型
        if file.content_type not in settings.ALLOWED_AVATAR_TYPES:
            raise ValueError(f"Only {', '.join(settings.ALLOWED_AVATAR_TYPES)} are allowed")
        
        try:
            # 读取文件内容
            contents = await file.read()
            if len(contents) > settings.MAX_AVATAR_SIZE:
                raise ValueError(f"Avatar size exceeds maximum allowed ({settings.MAX_AVATAR_SIZE // 1024 // 1024}MB)")
            
            # 重置文件指针
            await file.seek(0)
            
            # 生成唯一文件名
            file_ext = os.path.splitext(file.filename)[1]
            new_filename = f"{user_id}_{uuid.uuid4().hex}{file_ext}"
            file_path = os.path.join(settings.AVATAR_DIR, new_filename)
            
            # 删除用户之前的头像（如果存在）
            user = await self.get_user(user_id)
            if user and user.get("avatar_url"):
                old_filename = os.path.basename(user["avatar_url"])
                old_path = os.path.join(settings.AVATAR_DIR, old_filename)
                if os.path.exists(old_path):
                    os.remove(old_path)
            
            # 保存新头像
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            
            # 更新数据库中的头像URL
            avatar_url = f"/uploads/avatars/{new_filename}"
            now = datetime.now(timezone.utc)
            
            await db.db.users.update_one(
                {"_id": ObjectId(user_id)},
                {"$set": {
                    "avatar_url": avatar_url,
                    "updated_at": now
                }}
            )
            
            return {"avatar_url": avatar_url}
            
        except Exception as e:
            # 确保在出错时关闭文件
            await file.close()
            raise e

user_service = UserService()