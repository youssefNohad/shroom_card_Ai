from fastapi import FastAPI, UploadFile, File, HTTPException, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from fastai.vision.all import *
from PIL import Image
import io
import uvicorn
import os
import pathlib
from pathlib import WindowsPath

# Fix for PosixPath on Windows
pathlib.PosixPath = WindowsPath

# Initialize the application
app = FastAPI(title="Mushroom Classifier API")

# CORS settings
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Ensure all origins are allowed
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods (GET, POST, ...)
    allow_headers=["*"],  # Allow all headers
)

# Static files service
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

# Load the model
model_path = "C:/Users/CM/Desktop/test api/shroom_card-master (1)/shroom_card-master/mushrooms (2).pkl"
if not os.path.exists(model_path):
    raise RuntimeError(f"Model file not found at {model_path}")

try:
    model = load_learner(model_path)
except Exception as e:
    raise RuntimeError(f"Failed to load model: {str(e)}")

# Classification categories
categories = [
    "Agaricus", "Amanita", "Boletus", "Cortinarius", 
    "Entoloma", "Hygrocybe", "Lactarius", "Russula", "Suillus"
]

async def predict_mushroom(image_bytes: bytes):
    """Classify the mushroom image"""
    try:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        pred, _, probs = model.predict(img)
        return {
            "prediction": str(pred),
            "probabilities": {cat: float(prob) for cat, prob in zip(categories, probs)}
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# API endpoint for classification
@app.post("/api/predict")
async def api_predict(file: UploadFile = File(...)):
    """API endpoint for classification"""
    if not file.content_type.startswith('image/'):
        raise HTTPException(400, detail="You must upload an image file")
    
    try:
        image_bytes = await file.read()
        result = await predict_mushroom(image_bytes)
        return JSONResponse(content=result)
    except Exception as e:
        raise HTTPException(500, detail=str(e))

# Web interface
@app.get("/", response_class=HTMLResponse)
async def web_interface(request: Request):
    """Main page of the app"""
    return templates.TemplateResponse("index.html", {"request": request})

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
