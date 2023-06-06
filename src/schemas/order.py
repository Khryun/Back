from datetime import date, time, timedelta
from typing import List
from pydantic import BaseModel, validator

class OrderInfo(BaseModel):
    service_id: int
    order_start: time
    order_end: time
    name_service: str
    cost: int
    
    @validator('order_start', pre=False)
    def parse_order_start(cls, value):
        return value.strftime('%H:%M')
    
    @validator('order_end', pre=False)
    def parse_order_end(cls, value):
        return value.strftime('%H:%M')  