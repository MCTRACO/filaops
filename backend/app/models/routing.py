"""
Routing models for production process definitions.

Routings define the sequence of operations (steps) needed to manufacture a product.
Each operation specifies what work center, estimated time, and setup requirements.
"""
from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime

from app.db.base import Base


class Routing(Base):
    """
    Routing - defines the manufacturing process for a product.
    
    A routing is a sequence of operations that define how to make something.
    For 3D printing: typically just one operation (print)
    For assemblies: multiple operations (print parts, assemble, package)
    """
    __tablename__ = "routings"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey('products.id'), nullable=False)
    version = Column(String(50), default="V1.0", nullable=False)
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    
    # Status
    active = Column(Boolean, default=True, nullable=False)
    
    # Totals (calculated from operations)
    total_setup_minutes = Column(Numeric(10, 2), default=0, nullable=False)
    total_run_minutes = Column(Numeric(10, 2), default=0, nullable=False)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    created_by = Column(String(100), nullable=True)
    
    # Relationships
    product = relationship("Product", back_populates="routings")
    operations = relationship("RoutingOperation", back_populates="routing", 
                             cascade="all, delete-orphan", order_by="RoutingOperation.sequence")
    production_orders = relationship("ProductionOrder", back_populates="routing")
    
    def __repr__(self):
        return f"<Routing {self.name}: {len(self.operations)} operations>"

    @property
    def total_cycle_time_minutes(self):
        """Total time to complete one unit (setup + run)"""
        return float(self.total_setup_minutes or 0) + float(self.total_run_minutes or 0)


class RoutingOperation(Base):
    """
    A single operation (step) within a routing.
    
    Examples:
    - "Print Parts" - 3D print operation
    - "Remove Supports" - Post-processing
    - "Assemble Components" - Manual assembly
    - "Package for Shipping" - Final packaging
    """
    __tablename__ = "routing_operations"

    id = Column(Integer, primary_key=True, index=True)
    routing_id = Column(Integer, ForeignKey('routings.id', ondelete='CASCADE'), nullable=False)
    work_center_id = Column(Integer, ForeignKey('work_centers.id'), nullable=False)
    
    # Sequence and identification
    sequence = Column(Integer, nullable=False)  # 10, 20, 30... (allows insertion)
    operation_code = Column(String(50), nullable=True)  # "PRINT", "ASSY", "PACK"
    operation_name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    
    # Time estimates (minutes per unit)
    setup_minutes = Column(Numeric(10, 2), default=0, nullable=False)  # One-time setup
    run_minutes_per_unit = Column(Numeric(10, 2), nullable=False)      # Per unit time
    
    # Resource requirements
    required_skill = Column(String(100), nullable=True)  # "operator", "technician", "automated"
    simultaneous_capacity = Column(Integer, default=1, nullable=False)  # How many units can run at once
    
    # 3D Printing specific
    supports_required = Column(Boolean, default=False, nullable=False)
    infill_percent = Column(Numeric(5, 2), nullable=True)
    layer_height_mm = Column(Numeric(6, 3), nullable=True)
    
    # Instructions
    work_instructions = Column(Text, nullable=True)
    safety_notes = Column(Text, nullable=True)
    
    # Status
    active = Column(Boolean, default=True, nullable=False)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    routing = relationship("Routing", back_populates="operations")
    work_center = relationship("WorkCenter")
    production_order_operations = relationship("ProductionOrderOperation", back_populates="routing_operation")
    
    def __repr__(self):
        return f"<RoutingOperation {self.sequence}: {self.operation_name}>"

    def calculate_run_minutes(self, quantity: float) -> float:
        """Calculate total run time for a given quantity"""
        if self.simultaneous_capacity and self.simultaneous_capacity > 1:
            # For operations that can handle multiple units at once (like 3D printing)
            cycles = quantity / self.simultaneous_capacity
            return float(cycles * self.run_minutes_per_unit)
        else:
            # For operations that handle one unit at a time
            return float(quantity * self.run_minutes_per_unit)

    def calculate_total_minutes(self, quantity: float) -> float:
        """Calculate total time including setup"""
        return float(self.setup_minutes or 0) + self.calculate_run_minutes(quantity)
