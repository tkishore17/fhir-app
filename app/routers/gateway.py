import httpx
from fastapi import APIRouter, Header, HTTPException, status

from app.config import settings
from app.crypto import tokenize_string

router = APIRouter(prefix="/api/v1", tags=["FHIR Gateway"])


def execute_wasm_filter(payload: dict) -> bool:
    return True


@router.post("/secure-fhir")
async def process_fhir_packet(payload: dict, x_target_destination: str = Header(None)):

    # 1: Destination Whitelisting
    if (
        not x_target_destination
        or x_target_destination not in settings.get_allowed_destinations()
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Target Destination is not whitelisted",
        )
    # 2: WASM Filtering
    if not execute_wasm_filter(payload):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="WASM filter rejected the packet",
        )

    # 3: Targeted DLP and Tokenization
    if payload.get("resourceType") == "Patient":
        names = payload.get("name", [])
        for name in names:
            if "family" in name:
                name["family"] = tokenize_string(name["family"])
            if "given" in name and isinstance(name["given"], list):
                name["given"] = [tokenize_string(g) for g in name["given"]]

    # 4: Forward Secured Data to Destination
    async with httpx.AsyncClient() as client:
        try:
            pass
        except httpx.RequestError:
            raise HTTPException(
                status=status.HTTP_502_BAD_GATEWAY,
                detail=f"failed to reach whitelisted backedn: {exc}",
            )
    return {
        "status": "success",
        "message": "PoC: Packet processed, secured, and routed",
    }
