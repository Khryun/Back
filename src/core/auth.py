from src.database import get_connector

from typing import Annotated
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from starlette import status
from psycopg2._psycopg import connection
from .jwtoken import decode_access_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

class User:
    def __init__(self, conn, role):
        self.conn: connection = conn
        self.role: str = role

def get_current_connector(token: Annotated[str, Depends(oauth2_scheme)],
                           con: connection = Depends(get_connector)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        user_id = decode_access_token(token, credentials_exception)
        with get_connector() as con:
            with con.cursor() as cur:
                cur.execute('''SELECT login, post
                                FROM users
                                    INNER JOIN employees USING(employee_id)
                                WHERE user_id = %s''', (user_id,))
                role = cur.fetchone()
                if not role:
                    raise credentials_exception
                cur.execute('''SET ROLE %s;''', (role.get('login'), ))
        return User(conn=con, role=role.get('post'))
    except JWTError:
        raise credentials_exception
