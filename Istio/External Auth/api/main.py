from fastapi import FastAPI, APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from typing import Dict, List
from pydantic import BaseModel
import json, uvicorn

router = APIRouter(prefix="/api/v1")

# In-memory dictionary to store items
items = []
templates = Jinja2Templates(directory="templates")
ITEM_NOT_FOUND = {"error": "Item not found"}
# In-memory list of dictionaries to store items

with open('data.json', 'r') as f:
    items = json.load(f)['items']

# Item model
class Item(BaseModel):
    id: int
    name: str
    quantity: int
    cost: float
    apiVersion: str = "v1"

@router.get("/home", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse("home.html", {"request": request})

@router.get("/reset")  
def reset():
    """
    The reset function resets the data to its original state.
        :return: A message indicating that the reset was successful.
    
    :return: A dictionary with a message
    :doc-author: Sayed Imran
    """
    global items
    items = []
    with open('data.json', 'r') as f:
        items = json.load(f)['items']
    return {"message": "Data reset"}


# Get all items
@router.get("/items", response_model=List[Item])
def get_items():
    """
    The get_items function returns a list of items.
        :return: A list of items.
    
    
    :return: A list of items
    :doc-author: Sayed Imran
    """
    return items

# Get a single item by ID
@router.get("/items/{item_id}")
def get_item(item_id: int):
    """
    The get_item function returns the item with the given id.
    If no such item exists, it returns a dictionary containing an error message.
    
    :param item_id: int: Specify the type of data that is expected to be passed in
    :return: A dictionary with the item id, name and price
    :doc-author: Sayed Imran
    """
    try:
        return next(
            (item for item in items if item["id"] == item_id),
            ITEM_NOT_FOUND,
        )
    except Exception as e:
        return {"error": str(e)}

# Create a new item
@router.post("/items", response_model=Item)
def create_item(item: Item):
    """
    The create_item function creates a new item in the items list.
        Args:
            item (Item): The Item object to be created.
        Returns:
            dict: A dictionary containing the newly created Item object, or an error message if something went wrong.
    
    :param item: Item: Create a new item
    :return: A dictionary
    :doc-author: Sayed Imran
    """
    try:
        new_item = item.dict()
        items.append(new_item)
        return new_item
    except Exception as e:
        return {"error": str(e)}

# Update an existing item
@router.put("/items/{item_id}")
def update_item(item_id: int, item: Item):
    """
    The update_item function updates an item in the items list.
        Args:
            item_id (int): The id of the item to update.
            item (Item): The updated Item object with new values for name and price.
        Returns:
            dict: A dictionary containing a success message or error message if something went wrong.
    
    :param item_id: int: Identify the item to be updated
    :param item: Item: Pass the item object to the function
    :return: The updated item if it is found, otherwise it returns the item_not_found constant
    :doc-author: Sayed Imran
    """
    try:
        for existing_item in items:
            if existing_item["id"] == item_id:
                existing_item.update(item.dict())
                return item
        return ITEM_NOT_FOUND
    except Exception as e:
        return {"error": str(e)}

# Delete an item
@router.delete("/items/{item_id}")
def delete_item(item_id: int):
    """
    The delete_item function deletes an item from the items list.
        
    
    :param item_id: int: Specify the id of the item to be deleted
    :return: A dictionary with a message key and a value of &quot;item deleted&quot; if the item is found
    :doc-author: Sayed Imran
    """
    try:
        for idx, item in enumerate(items):
            if item["id"] == item_id:
                del items[idx]
                return {"message": "Item deleted"}
        return ITEM_NOT_FOUND
    except Exception as e:
        return {"error": str(e)}


app = FastAPI()
app.include_router(router)

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=7000, reload=True)