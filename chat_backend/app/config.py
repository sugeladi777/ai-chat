import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

class Settings:
     # 新增配置
    SECRET_KEY = "your-secret-key-for-jwt"  # 在实际应用中应使用安全的随机密钥
    ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24小时
    
    # 应用配置
    APP_NAME = "Chat Backend API"
    API_V1_STR = "/api/v1"
    
    # 数据库配置
    MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    DATABASE_NAME = os.getenv("DATABASE_NAME", "chat_app")
    
    # 智谱AI模型配置 - 只需要一个API KEY
    AI_API_KEY = os.getenv("AI_API_KEY")
    
    # 智谱AI模型配置
    AI_MODELS = {
        "default": "glm-4",  # 默认使用GLM-4
        "1": "glm-4",        # 对应用户请求中的model_id="1"
        "2": "glm-3-turbo",  # 可以添加其他模型
        "advanced": "glm-4-vision"  # 支持图像的模型
    }
    
    # 文件配置
    UPLOAD_DIR = "uploads"
    MAX_UPLOAD_SIZE = 10 * 1024 * 1024  # 10MB
    
    # 头像配置 - 新增
    AVATAR_DIR = os.path.join(UPLOAD_DIR, "avatars")
    MAX_AVATAR_SIZE = 2 * 1024 * 1024  # 2MB
    ALLOWED_AVATAR_TYPES = ["image/jpeg", "image/png", "image/gif"]

settings = Settings()