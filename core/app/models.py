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
    refresh_token: str | None = None
    expires_in: str | int | None = None

class UserProfile(BaseModel):
    uid: str
    email: str
    first_name: str
    last_name: str
    onboarded: bool = False

class Benefit(BaseModel):
    category: str
    title: str
    description: str
    details: str | None = None

class Card(BaseModel):
    id: str | None = None
    name: str
    brand: str
    benefits: list[Benefit]

class UserCard(BaseModel):
    card_id: str
    name: str
    brand: str
    # We might not need benefits for the list view, but helpful
    benefits: list[Benefit] | None = None
