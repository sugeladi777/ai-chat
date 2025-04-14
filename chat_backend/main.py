import contextlib
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import api_router
from app.database import connect_to_mongo, close_mongo_connection
from app.config import settings

@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动事件 - 在应用启动时执行
    await connect_to_mongo()
    yield
    # 关闭事件 - 在应用关闭时执行
    await close_mongo_connection()

app = FastAPI(title=settings.APP_NAME, lifespan=lifespan)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 在生产环境中应该限制为特定的源
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    return {"message": "Chat Backend API"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)