from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings
from pymongo import MongoClient
from dotenv import load_dotenv
import uvicorn


class Config(BaseSettings):
    mongo_uri: str 
    image_service: str 
    port: int = 8080

load_dotenv()
config = Config()
mongo_client = MongoClient(config.mongo_uri)

app=FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.get("/{animal}")
def get_animal_details(animal: str):
    pipeline = [
        {
            "$addFields": {
                "image_url": {
                    "$concat": [
                        config.image_service, "/", animal, "/", {"$toString": "$id"}
                    ]
                }
            }
        },
        {
            "$sample": {
                "size": 30
            }
        },
        {
            "$project": {
                "_id": 0,
                "id": 1, 
                "color": 1,
                "image_url": 1,
                "likes": 1,
                "description": 1,
                "user":{
                    "name": 1,
                    "location": 1
                }
            }
        }
    ]
    records = mongo_client["data"][animal].aggregate(pipeline)
    return list(records)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=config.port)