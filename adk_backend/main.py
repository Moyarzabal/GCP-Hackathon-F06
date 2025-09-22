"""
ADK-based Meal Planning API Server
FastAPI implementation with Google ADK agents
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
from dotenv import load_dotenv
from contextlib import asynccontextmanager
import structlog

from app.core.config import Settings
from app.core.logging import setup_logging
from app.api.v1.router import api_router
from app.core.exceptions import MealPlanningException

# Load environment variables
load_dotenv()

# Setup logging
setup_logging()
logger = structlog.get_logger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management"""
    # Startup
    logger.info("Starting ADK Meal Planning API Server")
    yield
    # Shutdown
    logger.info("Shutting down ADK Meal Planning API Server")

def create_app() -> FastAPI:
    """Create and configure FastAPI application"""
    
    app = FastAPI(
        title="ADK Meal Planning API",
        description="AI-powered meal planning using Google ADK agents",
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
    )
    
    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Configure appropriately for production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include API router
    app.include_router(api_router, prefix="/api/v1")
    
    @app.get("/health")
    async def health_check():
        """Health check endpoint"""
        return {"status": "healthy", "service": "adk-meal-planning-api"}
    
    @app.exception_handler(MealPlanningException)
    async def meal_planning_exception_handler(request, exc: MealPlanningException):
        """Handle meal planning specific exceptions"""
        logger.error("Meal planning error", error=str(exc), error_code=exc.error_code)
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": exc.error_code,
                "message": exc.message,
                "details": exc.details
            }
        )
    
    @app.exception_handler(Exception)
    async def general_exception_handler(request, exc: Exception):
        """Handle general exceptions"""
        logger.error("Unhandled exception", error=str(exc), exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "error": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected error occurred",
                "details": str(exc) if os.getenv("DEBUG") == "true" else None
            }
        )
    
    return app

# Create app instance
app = create_app()

if __name__ == "__main__":
    settings = Settings()
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
        log_level="info"
    )
