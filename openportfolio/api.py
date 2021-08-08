from fastapi import FastAPI

api = FastAPI()

@api.get("/")
def index():
    return {
        "greeting": "Welcome to OpenPortfolio"
    }
