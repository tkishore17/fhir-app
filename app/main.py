from fastapi import FastAPI
from app.router.gateway import router as fhir_router

def create_app() -> FastAPI:
    app = FastAPI(
        title       = "FHIR Security Engine Gateway",
        description = "PoC Edge Gateway for  Tokeniziation, WASM validation, and DLP",
        version     = "1.0.0"
    )

    app.include_router(fhir_router)
    return app

app = create_app()
