import contextlib
import uvicorn
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles  # 导入StaticFiles
from app.api.routes import api_router
from app.database import connect_to_mongo, close_mongo_connection
from app.config import settings
from fastapi.security import HTTPBearer

@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动事件 - 在应用启动时执行
    # 确保上传目录存在
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    os.makedirs(settings.AVATAR_DIR, exist_ok=True)
    
    await connect_to_mongo()
    yield
    # 关闭事件 - 在应用关闭时执行
    await close_mongo_connection()

# 定义安全组件
security = HTTPBearer(
    bearerFormat="JWT",
    description="Enter JWT token with Bearer prefix, e.g. 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'"
)

# 创建FastAPI应用
app = FastAPI(
    title=settings.APP_NAME,
    description="Chat application API with JWT authentication",
    version="1.0.0",
    lifespan=lifespan
)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 挂载静态文件目录 - 新增
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# 注册路由
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    return {"message": "Chat Backend API"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)