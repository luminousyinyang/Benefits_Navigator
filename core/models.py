from pydantic import BaseModel, EmailStr

class UserSignup(BaseModel):
    email: EmailStr
    password: str
    first_name: str
    last_name: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    id_token: str
    local_id: str
    email: str

class UserProfile(BaseModel):
    uid: str
    email: str
    first_name: str
    last_name: str
