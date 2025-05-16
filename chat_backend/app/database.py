from motor.motor_asyncio import AsyncIOMotorClient
from app.config import settings

class Database:
    client = None
    db = None

    async def connect(self):
        """连接到MongoDB数据库并创建必要的索引"""
        try:
            # 使用配置中的连接参数
            self.client = AsyncIOMotorClient(
                settings.MONGODB_URL,
                serverSelectionTimeoutMS=5000,  # 设置较短的超时时间便于快速反馈
                connectTimeoutMS=5000
            )
            
            # 选择数据库
            self.db = self.client[settings.DATABASE_NAME]
            
            # 验证连接是否成功
            await self.client.admin.command('ping')
            print(f"Connected to MongoDB at {settings.MONGODB_URL}")
            
            # 创建索引 - 为用户表创建唯一索引
            if 'users' in await self.db.list_collection_names():
                # 为用户名和邮箱创建唯一索引
                await self.db.users.create_index("username", unique=True)
                await self.db.users.create_index("email", unique=True)
                print("User indexes created/verified")
            
            return self.db
        except Exception as e:
            print(f"Failed to connect to MongoDB: {e}")
            raise

    async def disconnect(self):
        """关闭MongoDB连接"""
        if self.client:
            self.client.close()
            print("Disconnected from MongoDB")

db = Database()

async def connect_to_mongo():
    """应用启动时连接数据库"""
    await db.connect()

async def close_mongo_connection():
    """应用关闭时断开数据库连接"""
    await db.disconnect()