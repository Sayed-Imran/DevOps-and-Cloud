import asyncio
import uvicorn
from minio import Minio
from io import BytesIO
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from concurrent.futures import ThreadPoolExecutor
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

app=FastAPI()

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

class Config(BaseSettings):
    minio_endpoint: str
    minio_access_key: str = "minioadmin"
    minio_secret_key: str = "minioadmin"
    minio_secure: bool = False
    port: int = 8000

load_dotenv()
config = Config()
MINIO_CLIENT = Minio(
    endpoint=config.minio_endpoint,
    access_key=config.minio_access_key,
    secret_key=config.minio_secret_key,
    secure=config.minio_secure
)

BUCKET_NAME = "images"

executor = ThreadPoolExecutor()

def get_image_from_minio(image_name: str):
    try:
        return MINIO_CLIENT.get_object(BUCKET_NAME, image_name)
    except Exception as e:
        raise FileNotFoundError(f"Image '{image_name}' not found. Error: {str(e)}")

@app.get("/images/{object}/{image_id}")
async def get_image(object: str, image_id: str):
    try:
        image_path= f"{object}/{image_id}.jpg"
        
        response = await asyncio.get_event_loop().run_in_executor(
            executor, get_image_from_minio, image_path
        )

        image_data = BytesIO(await asyncio.get_event_loop().run_in_executor(executor, response.read))
        response.close()
        response.release_conn()

        return StreamingResponse(image_data, media_type="image/jpeg")
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=config.port)
