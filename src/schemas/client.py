from datetime import time, date
import re
from pydantic import BaseModel, EmailStr, validator


class ClientCreate(BaseModel):
    client_name: str
    phone_number: str
    email: EmailStr | None
    
    @validator('phone_number')
    def parse_phone_number(cls, value):
      regex = r'(\+7) (\(9(\d{2})\)) (\d{3})-(\d{2})-(\d{2})'
      if value and not re.match(regex, value):
          raise ValueError("Phone Number Invalid.")
      return value
    
class ClientInfo(ClientCreate):
    client_id: int
    email: EmailStr | None
    amount_visits: int 
    bonus: int 
    estate: str


class ClientUpdate(ClientCreate):
    pass
    
