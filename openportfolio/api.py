from fastapi import FastAPI


api = FastAPI()

@api.get("/")
def index():
    return {
        "greeting": "Welcome to OpenPortfolio"
    }

@api.get("/random")
def random(granularity: Granularity)
