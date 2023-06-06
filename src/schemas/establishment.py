from pydantic import BaseModel

class EstablishmentBase(BaseModel):
    establishment_id: int
    address_: str
    postcode: int
    phonenumber: str
    empl_amount: int
    
class EstablishmentReport(BaseModel):
    establishment_id: int
    address: str
    profit: int
    amount_checks: int