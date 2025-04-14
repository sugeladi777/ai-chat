import os
import aiofiles
import uuid
from fastapi import UploadFile
from app.config import settings

class FileService:
    def __init__(self):
        # 确保上传目录存在
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    
    async def save_file(self, file: UploadFile) -> str:
        """
        保存上传的文件并返回文件路径
        """
        # 生成唯一文件名
        file_ext = os.path.splitext(file.filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_ext}"
        file_path = os.path.join(settings.UPLOAD_DIR, unique_filename)
        
        # 保存文件
        async with aiofiles.open(file_path, 'wb') as out_file:
            content = await file.read()
            await out_file.write(content)
        
        return file_path
    
    def delete_file(self, file_path: str) -> bool:
        """
        删除文件
        """
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                return True
            return False
        except Exception:
            return False
    
    async def export_chat(self, chat_data: dict, format: str = "md") -> str:
        """
        导出聊天内容为指定格式
        """
        export_id = str(uuid.uuid4())
        filename = f"chat_export_{export_id}.{format}"
        file_path = os.path.join(settings.UPLOAD_DIR, filename)
        
        if format == "md":
            content = self._format_as_markdown(chat_data)
        elif format == "txt":
            content = self._format_as_text(chat_data)
        else:
            raise ValueError(f"Unsupported export format: {format}")
        
        async with aiofiles.open(file_path, 'w') as f:
            await f.write(content)
            
        return file_path
    
    def _format_as_markdown(self, chat_data: dict) -> str:
        """
        将聊天内容格式化为Markdown
        """
        md_content = f"# {chat_data['title']}\n\n"
        md_content += f"Created: {chat_data['created_at'].strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        for msg in chat_data['messages']:
            role = "You" if msg['role'] == "user" else "Assistant"
            md_content += f"## {role}\n\n{msg['content']}\n\n"
            
        return md_content
    
    def _format_as_text(self, chat_data: dict) -> str:
        """
        将聊天内容格式化为纯文本
        """
        txt_content = f"{chat_data['title']}\n"
        txt_content += f"Created: {chat_data['created_at'].strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        for msg in chat_data['messages']:
            role = "You" if msg['role'] == "user" else "Assistant"
            txt_content += f"{role}:\n{msg['content']}\n\n"
            
        return txt_content

file_service = FileService()