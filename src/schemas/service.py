from pydantic import BaseModel
from datetime import timedelta

class ServiceBase(BaseModel):
    service_id: int
    service_title: str
    cost: int
    duration: timedelta
    
class ServiceReport(BaseModel):
    service_id: int 
    service_title: str 
    profit: int
    amount_checks: int