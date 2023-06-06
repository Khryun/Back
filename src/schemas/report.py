from pydantic import BaseModel
from datetime import date

class ReportDate(BaseModel):
    date_start: date
    date_end: date