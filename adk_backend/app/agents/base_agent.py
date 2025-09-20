"""
Base agent class for ADK meal planning agents
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, TypeVar, Generic
import structlog
from app.core.config import Settings

logger = structlog.get_logger(__name__)
settings = Settings()

T = TypeVar('T')  # Request type
R = TypeVar('R')  # Response type

class BaseAgent(ABC, Generic[T, R]):
    """Base class for all ADK agents"""
    
    def __init__(
        self,
        name: str,
        model: str = None,
        temperature: float = None,
        max_tokens: int = None
    ):
        self.name = name
        self.model = model or settings.default_model
        self.temperature = temperature or settings.default_temperature
        self.max_tokens = max_tokens or settings.default_max_tokens
        
        logger.info(
            "Initializing agent",
            agent_name=self.name,
            model=self.model,
            temperature=self.temperature,
            max_tokens=self.max_tokens
        )
    
    @abstractmethod
    async def process(self, request: T) -> R:
        """Process the request and return response"""
        pass
    
    @abstractmethod
    def get_system_prompt(self) -> str:
        """Get the system prompt for this agent"""
        pass
    
    def get_agent_config(self) -> Dict[str, Any]:
        """Get agent configuration"""
        return {
            "name": self.name,
            "model": self.model,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "system_prompt": self.get_system_prompt()
        }
    
    async def validate_request(self, request: T) -> None:
        """Validate the incoming request"""
        # Override in subclasses for specific validation
        pass
    
    async def preprocess_request(self, request: T) -> T:
        """Preprocess the request before processing"""
        # Override in subclasses for specific preprocessing
        return request
    
    async def postprocess_response(self, response: R) -> R:
        """Postprocess the response after processing"""
        # Override in subclasses for specific postprocessing
        return response
    
    async def handle_error(self, error: Exception, request: T) -> None:
        """Handle errors during processing"""
        logger.error(
            "Agent processing error",
            agent_name=self.name,
            error=str(error),
            request_type=type(request).__name__
        )
        raise error
