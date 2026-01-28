"""
Pytest configuration and fixtures for the test suite.
"""
import pytest
import sys
from pathlib import Path

# Add the backend directory to the path so imports work correctly
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))
