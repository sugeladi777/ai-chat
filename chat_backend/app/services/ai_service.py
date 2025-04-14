import zhipuai
from typing import List, Dict, Optional, Any
import os
import aiofiles
import asyncio
from app.config import settings

class AIService:
    def __init__(self):
        self.api_key = settings.AI_API_KEY
        self.models = settings.AI_MODELS
        # 初始化zhipuai客户端
        self.client = zhipuai.ZhipuAI(api_key=self.api_key)
        
    async def get_response(self, messages: List[Dict[str, str]], model_id: Optional[str] = None) -> str:
        """
        从智谱AI模型获取响应
        """
        model = self.models.get(model_id, self.models["default"])
        
        # 添加system消息（如果需要）
        if not any(msg.get("role") == "system" for msg in messages):
            messages.insert(0, {
                "role": "system", 
                "content": "你是一个有用的AI助手。"
            })
        
        # 由于zhipuai库是同步的，我们需要使用run_in_executor来避免阻塞事件循环
        loop = asyncio.get_event_loop()
        try:
            response = await loop.run_in_executor(
                None,
                lambda: self.client.chat.completions.create(
                    model=model,
                    messages=messages,
                    temperature=0.7
                )
            )
            
            # 返回内容 - 根据新版API调整返回内容的获取方式
            return response.choices[0].message.content
        except Exception as e:
            raise Exception(f"调用智谱AI失败: {str(e)}")
    
    async def process_file(self, file_path: str) -> str:
        """
        处理上传的文件，提取内容
        """
        file_ext = os.path.splitext(file_path)[1].lower()
        
        if file_ext in ['.txt', '.md']:
            # 文本文件
            async with aiofiles.open(file_path, 'r') as f:
                content = await f.read()
            return content
        
        elif file_ext in ['.jpg', '.png', '.jpeg']:
            # 图片文件
            # 如果使用智谱支持图片的模型，可以使用base64编码的方式发送图片
            return f"[图片文件: {os.path.basename(file_path)}]"
        
        elif file_ext in ['.pdf', '.ppt', '.pptx', '.doc', '.docx']:
            # 其他文档类型
            return f"[文档文件: {os.path.basename(file_path)}]"
        
        return f"[无法处理的文件: {os.path.basename(file_path)}]"

ai_service = AIService()