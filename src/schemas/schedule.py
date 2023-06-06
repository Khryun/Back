from datetime import date, time
import re
from pydantic import BaseModel, validator, root_validator


class ScheduleUpdate(BaseModel):
    work_date: date
    work_start: time
    work_end: time 
    presence: bool
    
    @root_validator
    def parse_times(cls, values):
        if values.get('work_end') <= values.get('work_start'):
            raise ValueError("Times Invalid")
        return values
    
class ScheduleCreate(ScheduleUpdate):
    presence: bool | None = True
    phonenumber: str
    
    @validator('phonenumber')
    def parse_phonenumber(cls, value):
      regex = r'(\+7) (\(9(\d{2})\)) (\d{3})-(\d{2})-(\d{2})'
      if value and not re.match(regex, value):
          raise ValueError("Phone Number Invalid")
      return value