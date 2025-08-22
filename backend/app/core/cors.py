from fastapi.middleware.cors import CORSMiddleware

def add_cors(app):
    # For dev: allow everything (mobile emulator / local web tools).
    # In staging/prod: replace with explicit origins list.
    origins = ["*"]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],   # GET, POST, PUT, DELETE, OPTIONS...
        allow_headers=["*"],   # Authorization, Content-Type, etc.
        expose_headers=["Content-Disposition"],  # helpful for file downloads
        max_age=600,           # preflight cache
    )
