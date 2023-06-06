import re
from typing import List
from pydantic import BaseModel, validator, EmailStr
from datetime import date, datetime

class SpecialistBase(BaseModel):
    employee_id: int
    employee_name: str

 
class SpecialistInfo(SpecialistBase):
    post: str


class SpecialistPeriod(BaseModel):
    date: date
    times: List[datetime]
    
    @validator('times', pre=False)
    def parse_time(cls, value):
        return [x.strftime('%H:%M') for x in value] 

    
class SpeciallistReport(SpecialistBase):
    profit: int
    amount_checks: int