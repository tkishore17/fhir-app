import os


class Settings:
    # Explicity load the key from GKE. Crash if it ins't injected
    CRYPT_SECRET_KEY: str = os.getenv("CRYPT_SECRET_KEY")
    if not CRYPT_SECRET_KEY:
        raise RuntimeError(
            "CRITICAL ERROR: CRYPT_SECRET_KEY environment variable not defined! Pod halting."
        )

    WHITELIST_FILE_PATH: str = "/etc/fhir-gateway/allowed-destinations.txt"

    WASM_MODULE_PATH: str = os.getenv("WASM_MODULE_PATH", "build-config/filter.wasm")

    def get_allowed_destinations(self) -> list[str]:
        if not os.path.exists(self.WHITELIST_FILE_PATH):
            return []

        try:
            with open(self.WHITELIST_FILE_PATH, "r") as f:
                content = f.read().strip()
                if not content or content == '""':
                    return []
                return [
                    domain.strip() for domain in content.split(",") if domain.strip()
                ]
        except Exception:
            return []


settings = Settings()
