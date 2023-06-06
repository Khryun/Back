import re
from typing import List
from pydantic import BaseModel, EmailStr, validator, root_validator
from datetime import date, time
from .specialist import SpecialistInfo

class EmployeeGetSchedule(BaseModel):
    schedule_id: int
    work_date: date 
    work_start: time 
    work_end: time
    employee_name: str
    post: str
    presence: bool
    address: str
    
    @validator('work_start', pre=False)
    def parse_work_start(cls, value):
        return value.strftime('%H:%M')
    
    @validator('work_end', pre=False)
    def parse_work_end(cls, value):
        return value.strftime('%H:%M')

class EmployeeInfo(SpecialistInfo):
    email: EmailStr | None
    experience: int
    salary: int
    brief_info: str | None
    age: int
    services_id: List[int] | None
    phonenumber: str

class EmployeeUpdate(BaseModel):
    email: EmailStr | None
    experience: int
    salary: int
    brief_info: str | None
    age: int
    services_id: List[int] | None = None
    employee_name: str
    phonenumber: str
    
    @validator('phonenumber')
    def parse_telephone(cls, value):
      regex = r'(\+7) (\(9(\d{2})\)) (\d{3})-(\d{2})-(\d{2})'
      if value and not re.match(regex, value):
          raise ValueError("Phone Number Invalid.")
      return value

class EmployeeCreate(EmployeeUpdate):
    post: str
    
class EmployeeRegister(BaseModel):
    password: str
    
    
class EmployeeLoginData(BaseModel):
    employee_id: int
    employee_name: str
    phonenumber: str
    post: str
    login: str | None