from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import JSONResponse

app = FastAPI()

@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"])
async def auth(path:str, role: str = Header(default=None)):
    """
    The auth function is a simple authorization function that checks the role of the user.
    If the user has an admin role, it returns a 200 response with an admin header.
    Otherwise, it returns a 401 response with an anonymous header and body message.

    :param path:str: Get the path of the request
    :param role: str: Pass the role of the user to the auth function
    :return: A jsonresponse object
    :doc-author: Sayed Imran
    """

    try:
        print(f"Role: {role}")
        print(f"Receving request on path: /{path}")
        if role == "admin":
            headers = {"role": "admin"}
            return JSONResponse(status_code=200, headers=headers, content=None)
        else:
            headers = {"role": "anonymous"}
            body = {"message": "You are not authorized to access this resource"}
            return JSONResponse(status_code=401, headers=headers, content=body)

    except Exception as e:
        raise HTTPException(status_code=401, detail="You are not authorized") from e


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000)